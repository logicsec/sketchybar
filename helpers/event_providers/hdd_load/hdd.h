#include <sys/statvfs.h>
#include <stdbool.h>
#include <unistd.h>
#include <stdio.h>

struct disk_info {
    unsigned long total_space;     // Total disk space in GB
    unsigned long free_space;      // Free disk space in GB
    unsigned long used_space;      // Used disk space in GB
    int percent_used;              // Percentage of used space
    int percent_remaining;          // Percentage of free space remaining
};

static inline void disk_init(struct disk_info* disk) {
    // Initialize disk information
    disk->total_space = 0;
    disk->free_space = 0;
    disk->used_space = 0;
    disk->percent_used = 0;
    disk->percent_remaining = 0;
}

static inline bool disk_update(struct disk_info* disk, const char* path) {
    struct statvfs stat;
    if (statvfs(path, &stat) != 0) {
        printf("Error: Could not read disk statistics for %s\n", path);
        return false;
    }

    // Total space in bytes
    unsigned long total_bytes = stat.f_blocks * stat.f_frsize;
    // Free space in bytes
    unsigned long free_bytes = stat.f_bfree * stat.f_frsize;
    
    // Convert to GB
    disk->total_space = total_bytes / (1024 * 1024 * 1024);
    disk->free_space = free_bytes / (1024 * 1024 * 1024);
    disk->used_space = disk->total_space - disk->free_space;

    // Calculate percentage of used and remaining space
    disk->percent_used = (disk->total_space > 0) ? ((disk->used_space * 100) / disk->total_space) : 0;
    disk->percent_remaining = (disk->total_space > 0) ? ((disk->free_space * 100) / disk->total_space) : 0;
    
    return true;
}
