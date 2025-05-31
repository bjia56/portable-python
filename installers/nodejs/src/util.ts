import { existsSync } from 'fs';
import { platform } from 'os';

export function isNixOS(): boolean {
    try {
        return platform() === "linux" && existsSync("/etc/NIXOS");
    } catch (e) {
        return false;
    }
}