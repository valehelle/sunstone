
self.addEventListener('push', function (event) {
    const title = 'Inoffice';
    console.log(event.data)
    console.log(event.data.json())
    const json = event.data.json()
    console.log(json)
    const options = {
        body: json.body
    };


    const notificationPromise = self.registration.showNotification(title, options);
    event.waitUntil(notificationPromise);

});