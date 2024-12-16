#include "hdd.h"
#include "../sketchybar.h"
#include <sys/statvfs.h>

int main (int argc, char** argv) {
    // Comment out stdout/stderr redirection for debugging
    // freopen("/dev/null", "w", stdout);
    // freopen("/dev/null", "w", stderr);
    
    float update_freq;
    if (argc < 3 || (sscanf(argv[2], "%f", &update_freq) != 1)) {
        printf("Usage: %s \"<event-name>\" \"<event_freq>\"\n", argv[0]);
        exit(1);
    }

    alarm(0);
    struct disk_info root_disk;
    struct disk_info external_disk;
    disk_init(&root_disk);
    disk_init(&external_disk);

    // Setup the event in sketchybar
    char event_message[512];
    snprintf(event_message, 512, "--add event '%s'", argv[1]);
    sketchybar(event_message);

    char trigger_message[1024];  
    for (;;) {
        // Acquire new disk info for both drives
        disk_update(&root_disk, "/");
        disk_update(&external_disk, "/Volumes/ExternalDrive");

        // Calculate combined free space in TB (with one decimal place)
        double total_free_tb = (root_disk.free_space + external_disk.free_space) / 1024.0;
        
        // Prepare the event message with available space in TB
        snprintf(trigger_message, 1024,
                "--trigger '%s' available='%.1fT'",
                argv[1],
                total_free_tb);

        // Trigger the event
        sketchybar(trigger_message);

        // Wait
        usleep(update_freq * 1000000);
    }
    return 0;
}
