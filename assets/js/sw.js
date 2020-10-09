
self.addEventListener('push', function (event) {
    const title = 'Inoffice';
    const json = event.data.json()
    const options = {
        body: json.body,
        silent: true,
    };


    const notificationPromise = self.registration.showNotification(title, options);
    event.waitUntil(notificationPromise);

});