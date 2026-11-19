cmake_minimum_required(VERSION 3.18.1)
project("qemu_wrapper")

add_library(
        qemu_wrapper
        SHARED
        qemu_wrapper.cpp)

find_library(
        log-lib
        log)

target_link_libraries(
        qemu_wrapper
        ${log-lib})
