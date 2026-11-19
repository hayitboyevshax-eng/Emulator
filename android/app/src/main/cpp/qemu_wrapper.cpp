#include <jni.h>
#include <string>
#include <cstdlib>
#include <android/log.h>

#define LOG_TAG "QemuWrapper"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

extern "C" {

__attribute__((visibility("default"))) __attribute__((used))
int start_qemu_instance(const char* img_path, const char* kernel_path, int ram_mb) {
    LOGI("Starting QEMU with IMG: %s, RAM: %d MB", img_path, ram_mb);
    
    std::string cmd = "qemu-system-aarch64 -M virt -cpu cortex-a57 -m " + std::to_string(ram_mb) +
                      " -drive file=" + std::string(img_path) + ",if=virtio,format=raw";
                      
    if (kernel_path != nullptr && std::string(kernel_path).length() > 0) {
        cmd += " -kernel " + std::string(kernel_path);
    }
    
    LOGI("Executing command: %s", cmd.c_str());
    int result = system(cmd.c_str());
    return result;
}

}
