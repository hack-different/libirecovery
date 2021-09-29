#cython: binding=True
#cython: language_level=3

import cython
from cpython.bytes cimport *
from libc.string cimport memcpy


cdef class BaseError(Exception):
    cdef dict _lookup_table
    cdef int16_t _c_errcode


cdef class RecoveryError(BaseError):
    def __init__(self, *args, **kwargs):
        self._lookup_table = {
            irecv_error_t.IRECV_E_SUCCESS: "Success",
            irecv_error_t.IRECV_E_NO_DEVICE: "No device",
            irecv_error_t.IRECV_E_OUT_OF_MEMORY: "Out of memory",
            irecv_error_t.IRECV_E_UNABLE_TO_CONNECT: "Unable to connect",
            irecv_error_t.IRECV_E_INVALID_INPUT: "Invalid input",
            irecv_error_t.IRECV_E_FILE_NOT_FOUND: "File not found",
            irecv_error_t.IRECV_E_USB_UPLOAD: "USB upload",
            irecv_error_t.IRECV_E_USB_STATUS: "USB status",
            irecv_error_t.IRECV_E_USB_INTERFACE: "USB interface",
            irecv_error_t.IRECV_E_USB_CONFIGURATION: "USB configuration",
            irecv_error_t.IRECV_E_PIPE: "pipe",
            irecv_error_t.IRECV_E_TIMEOUT: "timeout",
            irecv_error_t.IRECV_E_UNSUPPORTED: "unsupported",
            irecv_error_t.IRECV_E_UNKNOWN_ERROR: "unknown error"
        }
        BaseError.__init__(self, *args, **kwargs)


def irecv_error_return(func):
    def wrap_result_in_exception(*args):
        cdef irecv_error_t result

        result = func(*args)

        if result != irecv_error_t.IRECV_E_SUCCESS:
            raise RecoveryError(result)

    return wrap_result_in_exception


cdef class RecoveryClient:
    cdef irecv_client_t device

    def __init__(self, ecid: str, attempts: int = -1):
        cdef irecv_error_t result

        if attempts == -1:
            result = irecv_open_with_ecid(&self.device, ecid)
        else:
            result = irecv_open_with_ecid_and_attempts(&self.device, ecid, attempts)

        if result != irecv_error_t.IRECV_E_SUCCESS:
            raise RecoveryError(result)

        self.ecid = ecid

    def _raise_if_not_success(self, result: irecv_error_t):
        if result != irecv_error_t.IRECV_E_SUCCESS:
            raise RecoveryError(result)

    @irecv_error_return
    def reset(self):
        return irecv_reset(self.device)

    @irecv_error_return
    def close(self):
        return irecv_close(self.device)

    def get_device_info(self) -> dict:
        return <dict>irecv_get_device_info(self.device)


    def reconnect(self, pause: int):
        self.device = irecv_reconnect(self.device, pause)

    @irecv_error_return
    def saveenv(self):
        return irecv_saveenv(self.device)

    @irecv_error_return
    def getenv(self, name: bytes) -> bytes:
        cdef:
            char* value
            irecv_error_t result

        result = irecv_getenv(self.device, name, &value)
        self._raise_if_not_success(result)

        return bytes(value)

    @irecv_error_return
    def setenv(self, name: bytes, value: bytes):
        return irecv_setenv(self.device, name, value)

    @irecv_error_return
    def reboot(self):
        return irecv_reboot(self.device)

    @irecv_error_return
    def getret(self) -> int:
        cdef irecv_error_t result
        cdef unsigned int value

        result = irecv_getret(self.device, &value)
        self._raise_if_not_success(result)

        return value

    def get_mode(self) -> irecv_mode:
        cdef int value
        cdef irecv_error_t result

        result = irecv_get_mode(self.device, &value)
        self._raise_if_not_success(result)

        return value

    @irecv_error_return
    def send_command(self, command: str):
        return irecv_send_command(self.device, command)

    @irecv_error_return
    def send_file(self, path: str, notify: bool = False):
        return irecv_send_file(self.device, path, 1 if notify else 0)

    @irecv_error_return
    def self_buffer(self, buffer: bytes, notify: bool = False):
        return irecv_send_buffer(self.device, buffer, len(buffer), 1 if notify else 0)

    @irecv_error_return
    def receive_buffer(self, length: int) -> bytes:
        cdef char* buffer
        cdef irecv_error_t result

        if length < 0:
            raise RecoveryError(irecv_error_t.IRECV_E_INVALID_INPUT)

        result = PyBytes_FromStringAndSize(NULL, length)
        buffer = PyBytes_AS_STRING(result)
        irecv_recv_buffer(self.device, buffer, length)

        return result

    @irecv_error_return
    def send_command_breq(self, command: str, request: int):
        cdef unsigned char b_request

        b_request = request

        return irecv_send_command_breq(self.device, command, b_request)

    @irecv_error_return
    def execute_script(self, script: str):
        return irecv_execute_script(self.device, script)

