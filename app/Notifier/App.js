import React, { PureComponent } from 'react';
import {
    DrawerLayoutAndroid,
    Linking,
    Text,
    View
} from 'react-native';
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

export default class App extends PureComponent {
    deregisters = [];

    state = {
        location: 'newTask',
        locationParams: {},
    };

    goTo(newLocation, newLocationParams={}) {
        this.setState({
            location: newLocation,
            locationParams: newLocationParams,
        });
    }

    render() {
        const view = React.createElement(ROUTER[this.state.location], {
            goTo: this.goTo.bind(this),
            ...this.state.locationParams
        });

        return (
            <DrawerLayoutAndroid
              drawerWidth={ 300 }
              renderNavigationView={ this.renderNavigationView.bind(this) }>
                { view }
            </DrawerLayoutAndroid>
        );
    }

    renderNavigationView() {
        return (
            <View style={{ flex: 1, backgroundColor: '#fff' }}>
              <Text style={{ margin: 10, fontSize: 15, textAlign: 'left' }}>I'm in the Drawer!</Text>
            </View>
        );
    }

    async handleOpenedNotification(data) {
        console.log('Handling', data.id);
        const url = data.url;
        if (!url) {
            return;
        }

        const canOpen = await Linking.canOpenURL(url);
        if (!canOpen) {
            console.error(`Could not open ${url}`);

            return;
        }

        console.log('Opening', url);
        await Linking.openURL(url);

        const resultID = data.id;
        await API.ackTaskResult(resultID);
        console.log('Acked', resultID);
    }

    async componentDidMount() {
        console.log('Mount App');
        const enabled = await firebase.messaging().hasPermission();
        if (!enabled) {
            await firebase.messaging().requestPermission();
        }

        // const token = await firebase.messaging().getToken();

        // console.log(`FCM Token: ${token}`);

        const channel = new firebase.notifications.Android.Channel(
            'notifier',
            'notifier',
            firebase.notifications.Android.Importance.Max);
        await firebase.notifications().android.createChannel(channel);

        this.deregisters.push(firebase.notifications().onNotification((notification) => {
            console.log('Received', notification._title, notification._body);

            notification.android.setChannelId('notifier');
            notification.android.setPriority(firebase.notifications.Android.Priority.Max);
            notification.android.setAutoCancel(true);
            firebase.notifications().displayNotification(notification);
        }));

        this.deregisters.push(firebase.notifications().onNotificationOpened((notification) => {
            const data = notification.notification.data;
            console.log('Opened', data.id);
            this.handleOpenedNotification(data);
        }));

        const initialNotification = await firebase.notifications().getInitialNotification()
        if (!initialNotification) {
            return;
        }

        const data = initialNotification.notification.data;
        console.log('Initial', data.id);
        this.handleOpenedNotification(data);
    }

    componentWillUnmount() {
        console.log('Unmount App');
        for (const deregister of this.deregisters) {
            deregister();
        }
    }
};
