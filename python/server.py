from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from appium import webdriver
from appium.webdriver.common.appiumby import AppiumBy
from appium.options.android import UiAutomator2Options
import logging
from typing import Optional, Dict, cast, Set
import uvicorn
from contextlib import asynccontextmanager
import asyncio
import time
import hashlib

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


# 数据模型定义
class WindowEvent(BaseModel):
    type: str
    package_name: str
    activity_name: str
    timestamp: int
    source_changed: bool = False  # 添加标识页面源码是否改变的字段


# WebSocket连接管理器
class ConnectionManager:
    def __init__(self):
        self.active_connections: Set[WebSocket] = set()
        self.monitoring_task = None  # 添加监控任务引用
        self.ping_task = None  # 添加ping任务引用

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
        while True:  # 移除 is_monitoring 检��，使用 task cancellation 来控制
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
            # 接收并处理消息
            message = await websocket.receive_json()
            if message.get("type") == "pong":
                logger.debug("Received pong from client")
            else:
                logger.warning(f"Received unknown message type: {message.get('type')}")
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
