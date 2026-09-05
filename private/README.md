# private/

Your real, filled-in `compose.yaml` and `.env` files — the ones with actual
passwords, API keys and your domain in them.

**This entire directory is gitignored.** Nothing in here is ever pushed.

Keep a copy of each stack as you actually run it:

    private/aiometadata/compose.yaml
    private/aiometadata/.env
    private/jikan/.env
    ...

The published, scrubbed versions live in `stacks/`. When you change something on
the server, update both: the real file here, and the placeholder version in
`stacks/` if the *structure* changed.
