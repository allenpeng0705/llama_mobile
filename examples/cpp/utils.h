#ifndef CACTUS_EXAMPLES_UTILS_H
#define CACTUS_EXAMPLES_UTILS_H

#include <iostream>
#include <string>
#include <fstream>
#include <cstdlib>
#ifdef _WIN32
#include <windows.h>
#else
#include <sys/stat.h>
#endif

inline bool fileExists(const std::string& filepath) {
    std::ifstream f(filepath.c_str());
    return f.good();
}

inline bool directoryExists(const std::string& dirpath) {
    #ifdef _WIN32
        DWORD ftyp = GetFileAttributesA(dirpath.c_str());
        if (ftyp == INVALID_FILE_ATTRIBUTES) return false;
        return (ftyp & FILE_ATTRIBUTE_DIRECTORY) != 0;
    #else
        struct stat info;
        if (stat(dirpath.c_str(), &info) != 0) return false;
        return (info.st_mode & S_IFDIR) != 0;
    #endif
}

inline bool downloadFile(const std::string& url, const std::string& filepath, const std::string& filename_desc) {
    if (url.empty() || filepath.empty()) {
        if (filepath.empty()) {
            std::cout << "No filepath specified for " << filename_desc << ", skipping download." << std::endl;
        } else {
            std::cout << "No URL specified for " << filename_desc << " at " << filepath << ", skipping download." << std::endl;
        }
        return fileExists(filepath);
    }

    if (fileExists(filepath)) {
        std::cout << filename_desc << " already exists at " << filepath << std::endl;
        return true;
    }

    std::cout << "Downloading " << filename_desc << " from " << url << " to " << filepath << "..." << std::endl;
    std::string command = "curl -L -o \"" + filepath + "\" \"" + url + "\"";
    
    int return_code = system(command.c_str());

    if (return_code == 0 && fileExists(filepath)) {
        std::cout << filename_desc << " downloaded successfully." << std::endl;
        return true;
    } else {
        std::cerr << "Failed to download " << filename_desc << "." << std::endl;
        return false;
    }
}

#endif // CACTUS_EXAMPLES_UTILS_H 