"""Print the local MCP environment variable names used by a Codex config."""

import re
import sys

try:
    import tomllib
except ImportError:
    # The shell checker treats status 3 as a skipped capability check.
    raise SystemExit(3)


def local_mcp_variables(config_path):
    with open(config_path, "rb") as config_file:
        servers = tomllib.load(config_file).get("mcp_servers", {})

    names = set()
    for server in servers.values():
        transport = [server[key] for key in ("command", "url") if key in server]
        if len(transport) != 1:
            raise ValueError("Expected exactly one of command or URL")
        if not isinstance(transport[0], str):
            raise TypeError("Expected a command or URL string")
        enabled = server.get("enabled", True)
        if not isinstance(enabled, bool):
            raise TypeError("Expected a boolean enabled flag")
        if not enabled:
            continue
        env_vars = server.get("env_vars", [])
        if not isinstance(env_vars, list):
            raise TypeError("Expected an env_vars array")
        for entry in env_vars:
            if isinstance(entry, str):
                names.add(entry)
                continue
            if not isinstance(entry, dict):
                raise TypeError("Expected an environment variable name or table")
            source = entry.get("source", "local")
            if not isinstance(source, str):
                raise TypeError("Expected an environment variable source string")
            if source not in ("local", "remote"):
                raise ValueError("Invalid environment variable source")
            if source == "local":
                names.add(entry["name"])
        names.update(server.get("env_http_headers", {}).values())
        if "bearer_token_env_var" in server:
            names.add(server["bearer_token_env_var"])

    if not all(re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name) for name in names):
        raise ValueError("Invalid environment variable name")
    return sorted(names)


if __name__ == "__main__":
    try:
        variable_names = local_mcp_variables(sys.argv[1])
    except (AttributeError, IndexError, KeyError, OSError, TypeError, ValueError):
        raise SystemExit(1)
    for name in variable_names:
        print(name)
