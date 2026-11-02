# Instance matching

Run `Tests/InstanceIdentity/run.sh` on macOS. These standalone checks require no
application launch, Accessibility permission, or changes to user settings.
They cover NUL-delimited argument/environment parsing, paths with spaces,
missing/inaccessible processes, HOME matching, separate profile arguments,
wrong target apps, and ambiguous launchers. Current Cursor processes are also
printed to help manually verify integration.

## Behavior

FlashSpace discovers apps beneath `/Applications` and `~/Applications`, refreshing
every five seconds. Duplicate bundle IDs use a path-based identity for copies;
the bundle whose filename matches CFBundleName retains the original identity
(with path ordering as a tie breaker). Add each copied app separately to a
workspace. Existing assignments for a duplicate ID may need to be re-added.
Moving a copied app requires re-adding it, since its path is its identity.

Parall shortcuts use their existing bundle IDs. Running target processes resolve
to those IDs by matching the launcher's target bundle ID and its HOME, or its
`--user-data-dir` argument when Parall configures a separate data directory.
The latter takes precedence over HOME, including when a shell uses the normal
home folder. Ambiguous matches or unavailable process metadata fall back to the
original identity; they never select an arbitrary launcher. Launchers outside
those application folders and other launchers' custom isolation schemes are not
automatically discovered. PIDs and environment contents are never persisted.

## Manual acceptance

Use a development build with Accessibility permission. Assign normal Cursor and
its copy/Parall shortcut to different workspaces, then test show/hide, focus on
app activation, next/previous app, next/previous window, floating apps, and
open-on-activation. Also put both instances in one workspace and cycle between
them. Restart both processes and repeat to verify stable matching. Do not run
the installed production FlashSpace alongside the development build during this
check. The automated checks do not exercise window visibility or focus APIs.
