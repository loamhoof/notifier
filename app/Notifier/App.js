import React, { PureComponent } from 'react';
import {
    DrawerLayoutAndroid,
    Linking,
    StyleSheet,
    Text,
    TouchableNativeFeedback,
    View
} from 'react-native';
import firebase from 'react-native-firebase';

import Task from './components/task';
import Tasks from './components/tasks';
import NewTask from './components/task-new';
import UnackedResults from './components/results-unacked';

import API from './common/api';

const ROUTER = {
    task: Task,
    tasks: Tasks,
    newTask: NewTask,
    unackedResults: UnackedResults,
};

export default class App extends PureComponent {
    deregisters = [];

    state = {
        location: 'tasks',
        locationParams: {},
    };

    goTo(newLocation, newLocationParams={}) {
        this.setState({
            location: newLocation,
            locationParams: newLocationParams,
        });

        this.refs['drawer'].closeDrawer();
    }

    render() {
        const view = React.createElement(ROUTER[this.state.location], {
            goTo: this.goTo.bind(this),
            ...this.state.locationParams
        });

        return (
            <DrawerLayoutAndroid
              ref='drawer'
              drawerWidth={ 300 }
              renderNavigationView={ this.renderNavigationView.bind(this) }>
                { view }
            </DrawerLayoutAndroid>
        );
    }

    renderNavigationView() {
        return (
            <View>
                <View>
                    <TouchableNativeFeedback
                        onPress={ this.goTo.bind(this, 'unackedResults') }>
                        <View style={ styles.navViewEl }>
                            <Text style={ styles.navViewText }>Notifications</Text>
                        </View>
                    </TouchableNativeFeedback>
                </View>
                <View>
                    <TouchableNativeFeedback
                        onPress={ this.goTo.bind(this, 'tasks') }>
                        <View style={ [styles.navViewEl, styles.navViewElBorder ] }>
                            <Text style={ styles.navViewText }>Tasks</Text>
                        </View>
                    </TouchableNativeFeedback>
                </View>
            </View>
        );
    }

    async handleOpenedNotification(data) {
        const url = data.url;
        if (!url) {
            return;
        }

        const canOpen = await Linking.canOpenURL(url);
        if (!canOpen) {
            console.error(`Could not open ${url}`);

            return;
        }

        await Linking.openURL(url);

        const resultID = data.id;
        await API.ackTaskResult(resultID);
    }

    async componentDidMount() {
        const enabled = await firebase.messaging().hasPermission();
        if (!enabled) {
            await firebase.messaging().requestPermission();
        }

        const channel = new firebase.notifications.Android.Channel(
            'notifier',
            'notifier',
            firebase.notifications.Android.Importance.Max);
        await firebase.notifications().android.createChannel(channel);

        this.deregisters.push(firebase.notifications().onNotification((notification) => {
            notification.android.setChannelId('notifier');
            notification.android.setPriority(firebase.notifications.Android.Priority.Max);
            notification.android.setAutoCancel(true);
            firebase.notifications().displayNotification(notification);
        }));

        this.deregisters.push(firebase.notifications().onNotificationOpened((notification) => {
            const data = notification.notification.data;
            this.handleOpenedNotification(data);
        }));

        const initialNotification = await firebase.notifications().getInitialNotification()
        if (!initialNotification) {
            return;
        }

        const data = initialNotification.notification.data;
        this.handleOpenedNotification(data);
    }

    componentWillUnmount() {
        for (const deregister of this.deregisters) {
            deregister();
        }
    }
};

const styles = StyleSheet.create({
    navViewEl: {
        paddingLeft: 30,
        height: 60,
        justifyContent: 'center'
    },
    navViewElBorder: {
        borderTopColor: '#000',
        borderTopWidth: 1
    },
    navViewText: {
        fontWeight: 'bold'
    }
});
