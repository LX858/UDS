![spooky](https://i.ytimg.com/vi/RNoHcWE8tbQ/maxresdefault.jpg)

# hackee-jumpscare
## QBCore admin command

`/troll <id> <time>` shows a jumpscare to an online player for `time` seconds.
For example, `/troll 12 5` targets server ID 12 for 5 seconds. Both arguments
must be positive integers. The command requires QBCore `admin` permission
(also supported through the Qbox QB bridge). Start the core before this resource.
Sending another troll to the same player restarts the duration.

The existing console-only `trollvn <id> true|false` command remains available
to manually show or hide the jumpscare.

The jumpscare displays a full-screen image and loops the screaming audio until
the duration expires or it is manually hidden.

 Note: You sometimes have to restart the resource before using for the sound to work.
