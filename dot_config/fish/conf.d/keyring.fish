if status is-login
    set -gx (gnome-keyring-daemon --start --components=pkcs11,secrets,ssh | string split '=')
end
