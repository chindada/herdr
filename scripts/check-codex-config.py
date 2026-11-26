"""Print the local MCP environment variable names used by a Codex config."""

import re
import sys

try:
    import tomllib
except ImportError:
    # The shell checker treats status 3 as a skipped capability check.
    raise SystemExit(3)


def overlay_tables(base, higher_priority):
    """Merge nested TOML tables, replacing other values with the newer entry."""
    for key, value in higher_priority.items():
        if isinstance(base.get(key), dict) and isinstance(value, dict):
            overlay_tables(base[key], value)
        else:
            base[key] = value


def local_mcp_variables(config_paths):
    config = {}
    for config_path in config_paths:
        with open(config_path, "rb") as config_file:
            overlay_tables(config, tomllib.load(config_file))

    names = set()
    for server in config.get("mcp_servers", {}).values():
        transport = [server[key] for key in ("command", "url") if key in server]
        if len(transport) != 1:
            raise ValueError("Expected exactly one of command or URL")
        if not isinstance(transport[0], str):
            raise TypeError("Expected a command or URL string")
        enabled = server.get("enabled", True)
        if not isinstance(enabled, bool):
            raise TypeError("Expected a boolean enabled flag")

        if "command" in server:
            if any(key in server for key in ("http_headers", "env_http_headers", "bearer_token_env_var")):
                raise ValueError("HTTP fields are not supported for stdio")
            args = server.get("args", [])
            if not isinstance(args, list) or not all(isinstance(arg, str) for arg in args):
                raise TypeError("Expected an args array of strings")

            env = server.get("env", {})
            if not isinstance(env, dict) or not all(isinstance(value, str) for value in env.values()):
                raise TypeError("Expected an env table of strings")
            env_vars = server.get("env_vars", [])
            if not isinstance(env_vars, list):
                raise TypeError("Expected an env_vars array")
            forwarded_names = set()
            for entry in env_vars:
                if isinstance(entry, str):
                    forwarded_names.add(entry)
                    continue
                if not isinstance(entry, dict) or not isinstance(entry.get("name"), str):
                    raise TypeError("Expected an environment variable name or table with a name")
                source = entry.get("source", "local")
                if source not in ("local", "remote"):
                    raise ValueError("Invalid environment variable source")
                if source == "local":
                    forwarded_names.add(entry["name"])
            server_names = forwarded_names - env.keys()
        else:
            if any(key in server for key in ("args", "env", "env_vars")):
                raise ValueError("Stdio fields are not supported for HTTP")
            literal_headers = server.get("http_headers", {})
            if not isinstance(literal_headers, dict) or not all(
                    isinstance(value, str) for value in literal_headers.values()):
                raise TypeError("Expected an http_headers table of strings")
            headers = server.get("env_http_headers", {})
            if not isinstance(headers, dict) or not all(isinstance(value, str) for value in headers.values()):
                raise TypeError("Expected an env_http_headers table of strings")
            server_names = set(headers.values())
            if "bearer_token_env_var" in server:
                bearer_token = server["bearer_token_env_var"]
                if not isinstance(bearer_token, str):
                    raise TypeError("Expected a bearer token environment variable name")
                server_names.add(bearer_token)

        if enabled:
            names.update(server_names)

    if not all(re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name) for name in names):
        raise ValueError("Invalid environment variable name")
    return sorted(names)


if __name__ == "__main__":
    try:
        variable_names = local_mcp_variables([sys.argv[1], *sys.argv[2:]])
    except (AttributeError, IndexError, KeyError, OSError, TypeError, ValueError):
        raise SystemExit(1)
    for name in variable_names:
        print(name)
