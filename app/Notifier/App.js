import React, { PureComponent } from 'react';
import firebase from 'react-native-firebase';

import Task from './components/task';
import Tasks from './components/tasks';
import NewTask from './components/task-new';

import API from './common/api';


const ROUTER = {
    task: Task,
    tasks: Tasks,
    newTask: NewTask,
};

let deregisters = [];
(async() => {
    const enabled = await firebase.messaging().hasPermission();
    if (!enabled) {
        await firebase.messaging().requestPermission();
    }

    const token = await firebase.messaging().getToken();

    console.log(`FCM Token: ${token}`);

    const channel = new firebase.notifications.Android.Channel(
        'notifier',
        'notifier',
        firebase.notifications.Android.Importance.Max);
    await firebase.notifications().android.createChannel(channel);

    deregisters.push(firebase.notifications().onNotification((notification) => {
        console.log('Received', notification._title, notification._body);

        notification.android.setChannelId('notifier');
        notification.android.setPriority(firebase.notifications.Android.Priority.Max);
        notification.android.setAutoCancel(true);
        firebase.notifications().displayNotification(notification);
    }));

    deregisters.push(firebase.notifications().onNotificationOpened(async(notification) => {
        console.log('Opened', notification.notification.data.id);

        const resultID = notification.notification.data.id;
        console.log(await API.ackTaskResult(resultID));
    }));
})();

export default class App extends PureComponent {
    state = {
        location: 'tasks',
        locationParams: {},
    };

    goTo(newLocation, newLocationParams={}) {
        this.setState({
            location: newLocation,
            locationParams: newLocationParams,
        });
    }

    render() {
        return React.createElement(ROUTER[this.state.location], {
            goTo: this.goTo.bind(this),
            ...this.state.locationParams
        });
    }

    componentWillUnmount() {
        for (const deregister of deregisters) {
            deregister();
        }
    }
};
