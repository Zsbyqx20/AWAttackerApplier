import asyncio
import base64
import hashlib
import json
import logging
import shutil
import tempfile
import time
from contextlib import asynccontextmanager
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Set, cast

import uvicorn
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from pydantic import BaseModel

# 配置日志
logger = logging.getLogger()
logHandler = logging.StreamHandler()
logHandler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
logger.addHandler(logHandler)
logger.setLevel(logging.INFO)

# Appium配置
APPIUM_SERVER = "http://localhost:4723"
CAPABILITIES = {
    "platformName": "Android",
    "automationName": "UiAutomator2",
    "noReset": True,
    "newCommandTimeout": 0,
    "nativeWebScreenshot": True,
    "systemPort": 8200,
    "adbExecTimeout": 60000,
    "uiautomator2ServerInstallTimeout": 60000,
    "skipServerInstallation": False,
    "enforceXPath1": True,
    "skipDeviceInitialization": False,
    "allowInsecure": ["adb_shell", "shell"],
}

# 添加新的配置常量
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)


# 数据模型定义
class WindowEvent(BaseModel):
    type: str
    package_name: str
    activity_name: str
    timestamp: int
    source_changed: bool = False  # 添加标识页面源码是否改变的字段


# 文件传输相关的数据模型
class FileTransferMessage(BaseModel):
    type: str  # 消息类型：START/CHUNK/END
    file_id: str  # 文件唯一标识
    total_chunks: Optional[int] = None  # 总分片数
    chunk_index: Optional[int] = None  # 当前分片索引
    chunk_data: Optional[str] = None  # Base64编码的分片数据
    timestamp: int  # 时间戳
    file_name: Optional[str] = None  # 添加文件名字段
    content_type: Optional[str] = None  # 添加内容类型字段


@dataclass
class FileTransferSession:
    file_id: str
    total_chunks: int
    received_chunks: List[Optional[str]]
    start_time: datetime
    last_update: datetime
    file_name: Optional[str] = None
    content_type: Optional[str] = None
    temp_file: Optional[Path] = None
    save_dir: Optional[Path] = UPLOAD_DIR  # 添加保存目录字段


# WebSocket连接管理器
class ConnectionManager:
    def __init__(self):
        self.active_connections: Set[WebSocket] = set()
        self.monitoring_task = None
        self.ping_task = None
        self.file_transfers: Dict[str, FileTransferSession] = {}
        self.temp_dir = Path(tempfile.gettempdir()) / "awattacker_transfers"
        self.temp_dir.mkdir(parents=True, exist_ok=True)

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.add(websocket)
        logger.info("New WebSocket client connected")

        # 第一个客户端连接时启动监控和ping任务
        if len(self.active_connections) == 1:
            self.monitoring_task = asyncio.create_task(monitor_window_changes())
            self.ping_task = asyncio.create_task(self.ping_clients())
            logger.info("Started window monitoring and ping task")

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
        logger.info("WebSocket client disconnected")

        # 最后一个客户端断开时停止所有任务
        if not self.active_connections:
            if self.monitoring_task:
                self.monitoring_task.cancel()
                self.monitoring_task = None
            if self.ping_task:
                self.ping_task.cancel()
                self.ping_task = None
            logger.info("Stopped all tasks")

    async def broadcast(self, event: WindowEvent):
        disconnected = set()
        for connection in self.active_connections:
            try:
                await connection.send_json(event.model_dump())
            except Exception as e:
                logger.error(f"Error sending event to client: {str(e)}")
                disconnected.add(connection)

        # 清理断开的连接
        for connection in disconnected:
            self.disconnect(connection)

    async def ping_clients(self):
        """定期发送ping消息给所有客户端"""
        try:
            while True:
                disconnected = set()
                for connection in self.active_connections:
                    try:
                        await connection.send_json({"type": "ping"})
                    except Exception as e:
                        logger.error(f"Error sending ping: {str(e)}")
                        disconnected.add(connection)

                # 清理断开的连接
                for connection in disconnected:
                    self.disconnect(connection)

                await asyncio.sleep(30)  # 30秒ping一次
        except asyncio.CancelledError:
            logger.info("Ping task cancelled")
            return

    async def handle_file_transfer(
        self, websocket: WebSocket, message: FileTransferMessage
    ):
        """处理文件传输消息"""
        try:
            if message.type == "START":
                # 创建临时文件
                temp_file = (
                    self.temp_dir
                    / f"{message.file_id}_{message.file_name or 'unnamed'}"
                )

                # 创建新的传输会话
                self.file_transfers[message.file_id] = FileTransferSession(
                    file_id=message.file_id,
                    total_chunks=message.total_chunks or 0,
                    received_chunks=[None] * (message.total_chunks or 0),
                    start_time=datetime.now(),
                    last_update=datetime.now(),
                    file_name=message.file_name,
                    content_type=message.content_type,
                    temp_file=temp_file,
                )

                # 发送确认消息
                await websocket.send_json({
                    "type": "FILE_TRANSFER_ACK",
                    "file_id": message.file_id,
                    "status": "started",
                    "temp_file": str(temp_file),
                })
                logger.info(f"Started file transfer session: {message.file_id}")

            elif message.type == "CHUNK":
                if message.file_id not in self.file_transfers:
                    raise ValueError(
                        f"No active transfer session for file_id: {message.file_id}"
                    )

                session = self.file_transfers[message.file_id]
                chunk_index = message.chunk_index or 0

                # 存储分片数据
                if 0 <= chunk_index < session.total_chunks:
                    session.received_chunks[chunk_index] = message.chunk_data
                    session.last_update = datetime.now()

                # 计算进度
                received_count = sum(
                    1 for chunk in session.received_chunks if chunk is not None
                )
                progress = (received_count / session.total_chunks) * 100

                # 发送进度更新
                await websocket.send_json({
                    "type": "FILE_TRANSFER_PROGRESS",
                    "file_id": message.file_id,
                    "progress": progress,
                    "received_chunks": received_count,
                    "total_chunks": session.total_chunks,
                })

                logger.debug(
                    f"Received chunk {chunk_index + 1}/{session.total_chunks} for file {message.file_id}"
                )

            elif message.type == "END":
                if message.file_id not in self.file_transfers:
                    raise ValueError(
                        f"No active transfer session for file_id: {message.file_id}"
                    )

                session = self.file_transfers[message.file_id]

                # 检查是否所有分片都已接收
                if None in session.received_chunks:
                    missing_chunks = [
                        i
                        for i, chunk in enumerate(session.received_chunks)
                        if chunk is None
                    ]
                    raise ValueError(
                        f"Incomplete transfer, missing chunks: {missing_chunks}"
                    )

                # 合并所有分片
                complete_data = "".join(
                    chunk for chunk in session.received_chunks if chunk is not None
                )

                # 处理完整的文件数据
                try:
                    decoded_data = base64.b64decode(complete_data)

                    # 根据内容类型处理数据
                    if session.content_type == "application/json":
                        # 解析JSON数据
                        json_data = json.loads(decoded_data.decode("utf-8"))

                        # 保存到临时文件
                        if session.temp_file:
                            with open(session.temp_file, "w", encoding="utf-8") as f:
                                json.dump(json_data, f, ensure_ascii=False, indent=2)

                            # 移动到最终保存位置
                            if session.save_dir:
                                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                                final_filename = (
                                    f"{timestamp}_{session.file_name or 'unnamed.json'}"
                                )
                                final_path = session.save_dir / final_filename
                                shutil.copy2(session.temp_file, final_path)
                                logger.info(f"File saved to: {final_path}")
                    else:
                        # 保存原始数据到临时文件
                        if session.temp_file:
                            with open(session.temp_file, "wb") as f:
                                f.write(decoded_data)

                            # 移动到最终保存位置
                            if session.save_dir:
                                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                                final_filename = (
                                    f"{timestamp}_{session.file_name or 'unnamed.bin'}"
                                )
                                final_path = session.save_dir / final_filename
                                shutil.copy2(session.temp_file, final_path)
                                logger.info(f"File saved to: {final_path}")

                    # 发送完成确认
                    await websocket.send_json({
                        "type": "FILE_TRANSFER_COMPLETE",
                        "file_id": message.file_id,
                        "status": "success",
                        "file_path": str(session.temp_file)
                        if session.temp_file
                        else None,
                        "saved_path": str(final_path)
                        if "final_path" in locals()
                        else None,
                    })
                    logger.info(f"File transfer completed: {message.file_id}")

                except Exception as e:
                    logger.error(f"Error processing complete file: {str(e)}")
                    await websocket.send_json({
                        "type": "FILE_TRANSFER_ERROR",
                        "file_id": message.file_id,
                        "error": str(e),
                    })
                finally:
                    # 清理临时文件
                    if session.temp_file and session.temp_file.exists():
                        try:
                            session.temp_file.unlink()
                            logger.debug(f"Temporary file removed: {session.temp_file}")
                        except Exception as e:
                            logger.error(f"Error removing temporary file: {str(e)}")
                    # 清理会话数据
                    del self.file_transfers[message.file_id]

        except Exception as e:
            logger.error(f"Error in file transfer: {str(e)}")
            await websocket.send_json({
                "type": "FILE_TRANSFER_ERROR",
                "file_id": message.file_id if hasattr(message, "file_id") else None,
                "error": str(e),
            })
            # 清理会话数据和临时文件
            if hasattr(message, "file_id") and message.file_id in self.file_transfers:
                session = self.file_transfers[message.file_id]
                if session.temp_file and session.temp_file.exists():
                    session.temp_file.unlink()
                del self.file_transfers[message.file_id]


# 创建连接管理器实例
manager = ConnectionManager()


class ObserverResponse(BaseModel):
    success: bool
    message: str


class ElementRequest(BaseModel):
    package_name: str
    activity_name: str
    element_info: Dict[str, str]  # 元素定位信息


class UiAutomatorRequest(BaseModel):
    package_name: str
    activity_name: str
    uiautomator_code: str  # UiAutomator代码


class QuickSearchRequest(BaseModel):
    element_info: Dict[str, str]  # 元素定位信息


class QuickUiAutomatorRequest(BaseModel):
    uiautomator_code: str  # UiAutomator代码


class ElementResponse(BaseModel):
    success: bool
    message: str
    coordinates: Optional[Dict[str, int]] = None  # x, y坐标
    size: Optional[Dict[str, int]] = None  # width, height
    visible: Optional[bool] = None
    element_id: Optional[str] = None


class BatchElementRequest(BaseModel):
    package_name: str
    activity_name: str
    elements: list[Dict[str, str]]  # 列表中每个字典包含一个元素的定位信息


class BatchUiAutomatorRequest(BaseModel):
    package_name: str
    activity_name: str
    uiautomator_codes: list[str]  # 列表中每个字符串是一个UiAutomator代码


class BatchQuickSearchRequest(BaseModel):
    elements: list[Dict[str, str]]  # 列表中每个字典包含一个元素的定位信息


class BatchQuickUiAutomatorRequest(BaseModel):
    uiautomator_codes: list[str]  # 列表中每个字符串是一个UiAutomator代码


class BatchElementResponse(BaseModel):
    success: bool
    message: str
    results: list[ElementResponse]


class ActivityResponse(BaseModel):
    success: bool
    message: str
    package_name: Optional[str] = None
    activity_name: Optional[str] = None


# 全局变量
driver = cast(webdriver.Remote, None)
is_monitoring = False


# lifespan 定义
@asynccontextmanager
async def lifespan(app: FastAPI):
    global driver
    try:
        options = UiAutomator2Options()
        options.load_capabilities(CAPABILITIES)
        logger.info("Connecting to Appium server at %s", APPIUM_SERVER)
        driver = webdriver.Remote(APPIUM_SERVER, options=options)
        logger.info("Successfully connected to Appium server")
        # 移除这里的监控任务启动
        # asyncio.create_task(monitor_window_changes())
    except Exception as e:
        logger.error(f"Failed to connect to Appium server: {str(e)}")
        raise
    yield
    if driver:
        driver.quit()
        logger.info("Appium driver closed")


# 创建 FastAPI 应用
app = FastAPI(title="AWAttacker Appium Server", lifespan=lifespan)


# 修改监控任务，实时推送事件
async def monitor_window_changes():
    global driver, is_monitoring
    last_package = None
    last_activity = None
    last_source_hash = None

    try:
        while True:  # 移除 is_monitoring 检查，使用 task cancellation 来控制
            try:
                current_package = driver.current_package
                current_activity = driver.current_activity

                # 获取当前页面源码并计算哈希值
                try:
                    current_source = driver.page_source
                    current_source_hash = hashlib.md5(
                        current_source.encode()
                    ).hexdigest()
                except Exception as e:
                    logger.error(f"Error getting page source: {str(e)}")
                    current_source_hash = None

                # 检查是否有变化
                source_changed = bool(
                    current_source_hash and current_source_hash != last_source_hash
                )
                has_changes = (
                    current_package != last_package
                    or current_activity != last_activity
                    or source_changed
                )

                if has_changes:
                    event = WindowEvent(
                        type="WINDOW_STATE_CHANGED",
                        package_name=current_package,
                        activity_name=current_activity,
                        timestamp=int(time.time() * 1000),
                        source_changed=source_changed,
                    )
                    await manager.broadcast(event)

                    last_package = current_package
                    last_activity = current_activity
                    last_source_hash = current_source_hash
                    logger.info(
                        f"Window state changed: {current_package}/{current_activity} "
                        f"(source changed: {event.source_changed})"
                    )

                await asyncio.sleep(0.1)

            except Exception as e:
                logger.error(f"Error monitoring window changes: {str(e)}")
                await asyncio.sleep(1.0)

    except asyncio.CancelledError:
        logger.info("Window monitoring task cancelled")
        return


# 添加WebSocket端点
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            message = await websocket.receive_json()
            message_type = message.get("type")

            if message_type == "pong":
                logger.debug("Received pong from client")
            elif message_type in ["START", "CHUNK", "END"]:
                # 处理文件传输消息
                transfer_message = FileTransferMessage(**message)
                await manager.handle_file_transfer(websocket, transfer_message)
            else:
                logger.warning(f"Received unknown message type: {message_type}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        logger.error(f"WebSocket error: {str(e)}")
        manager.disconnect(websocket)


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.post("/element", response_model=ElementResponse)
async def get_element_info(request: ElementRequest):
    global driver
    try:
        # 验证当前应用
        if not await verify_current_app(request.package_name, request.activity_name):
            return ElementResponse(
                success=False,
                message=f"Current app mismatch. Expected: {request.package_name}/{request.activity_name}, "
                f"Got: {driver.current_package}/{driver.current_activity}",
            )

        element = None
        for locator_type, locator_value in request.element_info.items():
            try:
                element = find_element_by_type(
                    driver, locator_type, locator_value, request.package_name
                )
                if element:
                    break
            except Exception as e:
                logger.debug(f"Failed to find element using {locator_type}: {str(e)}")
                continue

        return create_element_response(element)

    except Exception as e:
        logger.error(f"Error getting element info: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/element/uiautomator", response_model=ElementResponse)
async def get_element_by_uiautomator(request: UiAutomatorRequest):
    global driver
    try:
        # 验证当前应用
        if not await verify_current_app(request.package_name, request.activity_name):
            return ElementResponse(
                success=False,
                message=f"Current app mismatch. Expected: {request.package_name}/{request.activity_name}, "
                f"Got: {driver.current_package}/{driver.current_activity}",
            )

        try:
            element = driver.find_element(
                AppiumBy.ANDROID_UIAUTOMATOR, request.uiautomator_code
            )
            return create_element_response(element)
        except Exception as e:
            logger.debug(f"Failed to find element using UiAutomator: {str(e)}")
            return ElementResponse(success=False, message="Element not found")

    except Exception as e:
        logger.error(f"Error getting element info: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/quick_search", response_model=ElementResponse)
async def quick_search_element(request: QuickSearchRequest):
    global driver
    try:
        element = None
        current_package = driver.current_package

        for locator_type, locator_value in request.element_info.items():
            try:
                element = find_element_by_type(
                    driver, locator_type, locator_value, current_package
                )
                if element:
                    break
            except Exception as e:
                logger.debug(f"Failed to find element using {locator_type}: {str(e)}")
                continue

        return create_element_response(element)

    except Exception as e:
        logger.error(f"Error in quick search: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/quick_search/uiautomator", response_model=ElementResponse)
async def quick_search_by_uiautomator(request: QuickUiAutomatorRequest):
    global driver
    try:
        try:
            element = driver.find_element(
                AppiumBy.ANDROID_UIAUTOMATOR, request.uiautomator_code
            )
            return create_element_response(element)
        except Exception as e:
            logger.debug(f"Failed to find element using UiAutomator: {str(e)}")
            return ElementResponse(success=False, message="Element not found")

    except Exception as e:
        logger.error(f"Error in quick search: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/current_activity", response_model=ActivityResponse)
async def get_current_activity():
    global driver
    try:
        package_name = driver.current_package
        activity_name = driver.current_activity

        if package_name and activity_name:
            return ActivityResponse(
                success=True,
                message="Current activity info retrieved",
                package_name=package_name,
                activity_name=activity_name,
            )
        else:
            return ActivityResponse(
                success=False, message="Failed to get current activity info"
            )

    except Exception as e:
        logger.error(f"Error getting current activity: {str(e)}")
        return ActivityResponse(success=False, message=f"Error: {str(e)}")


@app.post("/batch/elements", response_model=BatchElementResponse)
async def get_batch_elements_info(request: BatchElementRequest):
    global driver
    try:
        # 验证当前应用
        if not await verify_current_app(request.package_name, request.activity_name):
            return BatchElementResponse(
                success=False,
                message=f"Current app mismatch. Expected: {request.package_name}/{request.activity_name}, "
                f"Got: {driver.current_package}/{driver.current_activity}",
                results=[],
            )

        results = []
        for element_info in request.elements:
            element = None
            for locator_type, locator_value in element_info.items():
                try:
                    element = find_element_by_type(
                        driver, locator_type, locator_value, request.package_name
                    )
                    if element:
                        break
                except Exception as e:
                    logger.debug(
                        f"Failed to find element using {locator_type}: {str(e)}"
                    )
                    continue

            results.append(create_element_response(element))

        return BatchElementResponse(
            success=True,
            message="Batch element search completed",
            results=results,
        )

    except Exception as e:
        logger.error(f"Error in batch element search: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/batch/elements/uiautomator", response_model=BatchElementResponse)
async def get_batch_elements_by_uiautomator(request: BatchUiAutomatorRequest):
    global driver
    try:
        # 验证当前应用
        if not await verify_current_app(request.package_name, request.activity_name):
            return BatchElementResponse(
                success=False,
                message=f"Current app mismatch. Expected: {request.package_name}/{request.activity_name}, "
                f"Got: {driver.current_package}/{driver.current_activity}",
                results=[],
            )

        results = []
        for uiautomator_code in request.uiautomator_codes:
            try:
                element = driver.find_element(
                    AppiumBy.ANDROID_UIAUTOMATOR, uiautomator_code
                )
                results.append(create_element_response(element))
            except Exception as e:
                logger.debug(f"Failed to find element using UiAutomator: {str(e)}")
                results.append(
                    ElementResponse(
                        success=False, message=f"Element not found: {str(e)}"
                    )
                )

        return BatchElementResponse(
            success=True,
            message="Batch UiAutomator search completed",
            results=results,
        )

    except Exception as e:
        logger.error(f"Error in batch UiAutomator search: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/batch/quick_search", response_model=BatchElementResponse)
async def batch_quick_search_elements(request: BatchQuickSearchRequest):
    global driver
    try:
        current_package = driver.current_package
        results = []

        for element_info in request.elements:
            element = None
            for locator_type, locator_value in element_info.items():
                try:
                    element = find_element_by_type(
                        driver, locator_type, locator_value, current_package
                    )
                    if element:
                        break
                except Exception as e:
                    logger.debug(
                        f"Failed to find element using {locator_type}: {str(e)}"
                    )
                    continue

            results.append(create_element_response(element))

        return BatchElementResponse(
            success=True,
            message="Batch quick search completed",
            results=results,
        )

    except Exception as e:
        logger.error(f"Error in batch quick search: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/batch/quick_search/uiautomator", response_model=BatchElementResponse)
async def batch_quick_search_by_uiautomator(request: BatchQuickUiAutomatorRequest):
    global driver
    try:
        results = []
        for uiautomator_code in request.uiautomator_codes:
            try:
                element = driver.find_element(
                    AppiumBy.ANDROID_UIAUTOMATOR, uiautomator_code
                )
                results.append(create_element_response(element))
            except Exception as e:
                logger.debug(f"Failed to find element using UiAutomator: {str(e)}")
                results.append(
                    ElementResponse(
                        success=False, message=f"Element not found: {str(e)}"
                    )
                )

        return BatchElementResponse(
            success=True,
            message="Batch quick UiAutomator search completed",
            results=results,
        )

    except Exception as e:
        logger.error(f"Error in batch quick UiAutomator search: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# 辅助函数
async def verify_current_app(package_name: str, activity_name: str) -> bool:
    return (
        driver.current_package == package_name
        and driver.current_activity == activity_name
    )


def find_element_by_type(
    driver, locator_type: str, locator_value: str, package_name: str
):
    if locator_type == "id":
        if ":" not in locator_value:
            locator_value = f"{package_name}:id/{locator_value}"
        return driver.find_element(AppiumBy.ID, locator_value)
    elif locator_type == "class_name":
        return driver.find_element(AppiumBy.CLASS_NAME, locator_value)
    elif locator_type == "accessibility_id":
        return driver.find_element(AppiumBy.ACCESSIBILITY_ID, locator_value)
    elif locator_type == "text":
        return driver.find_element(
            AppiumBy.ANDROID_UIAUTOMATOR, f'new UiSelector().text("{locator_value}")'
        )
    elif locator_type == "content-desc":
        return driver.find_element(
            AppiumBy.ANDROID_UIAUTOMATOR,
            f'new UiSelector().description("{locator_value}")',
        )
    return None


def create_element_response(element) -> ElementResponse:
    if not element:
        return ElementResponse(success=False, message="Element not found")

    location = element.location
    size = element.size
    is_displayed = element.is_displayed()
    element_id = element.id

    return ElementResponse(
        success=True,
        message="Element found",
        coordinates={"x": location["x"], "y": location["y"]},
        size={"width": size["width"], "height": size["height"]},
        visible=is_displayed,
        element_id=element_id,
    )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
