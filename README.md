# TaskFlow

TaskFlow is a Flutter task-management app.

## Configure the API server

The app uses `API_BASE_URL` to choose the backend API. The default is
`http://192.168.1.47:4000/api`, which is suitable only when the phone and API
server are on the same Wi-Fi network and the server accepts connections from
other devices on that network.

Build an Android APK with a different API URL:

```sh
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-server.example.com/api
```

For a physical phone connecting to a development server, use the computer's
LAN IP address rather than `localhost`, bind the server to an externally
reachable interface, and allow its port through the computer's firewall.
`localhost` on a phone refers to the phone itself.

Android internet permission is included in the main manifest so release builds
can make API requests. The app currently permits HTTP for the default LAN
development URL; use HTTPS for production because HTTP does not protect login
credentials or API traffic.
