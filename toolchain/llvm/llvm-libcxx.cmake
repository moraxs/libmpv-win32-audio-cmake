ExternalProject_Add(llvm-libcxx
    DEPENDS
        llvm-compiler-rt-builtin
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${LLVM_SRC}
    LIST_SEPARATOR ,
    CONFIGURE_COMMAND ${EXEC} CONF=1 cmake -H<SOURCE_DIR>/runtimes -B<BINARY_DIR>
        -G Ninja
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${MINGW_INSTALL_PREFIX}
        -DCMAKE_C_COMPILER=${TARGET_ARCH}-clang
        -DCMAKE_CXX_COMPILER=${TARGET_ARCH}-clang++
        -DCMAKE_SYSTEM_NAME=Windows
        -DCMAKE_AR=${CMAKE_INSTALL_PREFIX}/bin/llvm-ar
        -DCMAKE_RANLIB=${CMAKE_INSTALL_PREFIX}/bin/llvm-ranlib
        -DCMAKE_C_COMPILER_WORKS=1
        -DCMAKE_CXX_COMPILER_WORKS=1
        -DCMAKE_C_COMPILER_TARGET=${TARGET_CPU}-pc-windows-gnu
        -DLLVM_ENABLE_RUNTIMES='libunwind,libcxxabi,libcxx'
        -DLIBUNWIND_USE_COMPILER_RT=TRUE
        -DLIBUNWIND_ENABLE_SHARED=OFF
        -DLIBUNWIND_ENABLE_STATIC=ON
        -DLIBCXX_USE_COMPILER_RT=ON
        -DLIBCXX_ENABLE_SHARED=OFF
        -DLIBCXX_ENABLE_STATIC=ON
        -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=TRUE
        -DLIBCXX_CXX_ABI=libcxxabi
        -DLIBCXX_LIBDIR_SUFFIX=''
        -DLIBCXX_INCLUDE_TESTS=FALSE
        -DLIBCXXABI_INCLUDE_TESTS=FALSE
        -DLIBUNWIND_INCLUDE_TESTS=FALSE
        -DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=FALSE
        -DLIBCXX_HAS_WIN32_THREAD_API=ON
        -DLIBCXXABI_HAS_WIN32_THREAD_API=ON
        -DLIBCXXABI_USE_COMPILER_RT=ON
        -DLIBCXXABI_USE_LLVM_UNWINDER=ON
        -DLIBCXXABI_ENABLE_SHARED=OFF
        -DLIBCXXABI_LIBDIR_SUFFIX=''
    BUILD_COMMAND ${EXEC} LTO=0 ninja -C <BINARY_DIR>
    INSTALL_COMMAND ${EXEC} LTO=0 ninja -C <BINARY_DIR> install
            COMMAND bash -c "cp ${MINGW_INSTALL_PREFIX}/lib/libc++.a ${MINGW_INSTALL_PREFIX}/lib/libstdc++.a"
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

cleanup(llvm-libcxx install)

# mingw-w64 (since 2025-12) defines EXCEPTION_DISPOSITION as an enum and
# removed the ExceptionExecuteHandler define, which breaks libunwind's SEH
# code as shipped on the release/20.x branch. Force the backport of the
# upstream fix (llvm-project 0991d7b8fd01, #180513) to be re-applied before
# every configure; llvm's cleanup steps may revert it in the shared tree.
ExternalProject_Add_Step(llvm-libcxx force-patch
    DEPENDEES patch
    DEPENDERS configure
    ALWAYS 1
    COMMAND bash -c "cd <SOURCE_DIR> && (git checkout -- libunwind/src/Unwind-seh.cpp 2>/dev/null || true) && patch -p1 -N -i ${CMAKE_SOURCE_DIR}/packages/libunwind-seh-exception-disposition.patch"
    LOG 1
)
