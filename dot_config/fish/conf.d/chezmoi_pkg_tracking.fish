function __chezmoi_update_pkg_list --on-event fish_postexec
    # Capture the status of the command that just finished
    set -l last_status $status
    set -l cmd $argv[1]

    # Only update if the command succeeded
    if test $last_status -eq 0
        # Check if command looks like a package manager operation
        if string match -q -r '\b(pacman|paru)\b' -- $cmd
            # Only update if we are actually installing, removing or upgrading
            # simple heuristic: if it contains -S, -R, -U or just 'paru' (which acts as -Syu)
            if string match -q -r '(-[SRU]|paru)' -- $cmd
                 pacman -Qqe > ~/.local/share/chezmoi/packages.txt
            end
        end
    end
end
