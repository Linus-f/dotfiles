function __chezmoi_update_pkg_list --on-event fish_postexec
    # Capture the status of the command that just finished
    set -l last_status $status
    set -l cmd $argv[1]

    # Only update if the command succeeded
    if test $last_status -eq 0
        # Check if command looks like a package manager operation
        if string match -q -r '\b(pacman|paru)\b' -- $cmd
            # Only update if we are actually installing, removing or upgrading
            if string match -q -r '(-[SRU]|paru)' -- $cmd
                # Define paths
                set -l pkg_file ~/.local/share/chezmoi/packages.txt
                set -l sys_pkg_file ~/.local/share/chezmoi/sys_packages.txt

                # Generate user package list
                # If sys_packages.txt exists, filter against it (installed - system = user)
                if test -f $sys_pkg_file
                    pacman -Qqe | grep -vxFf $sys_pkg_file > $pkg_file
                else
                    # Fallback: dump everything if no baseline exists
                    pacman -Qqe > $pkg_file
                end
            end
        end
    end
end