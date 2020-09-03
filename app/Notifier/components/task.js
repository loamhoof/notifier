import React, { PureComponent } from 'react';
import {
    ActivityIndicator,
    Alert,
    Button,
    Linking,
    StyleSheet,
    Text,
    TouchableNativeFeedback,
    View
} from 'react-native';

import API from '../common/api';


export default class Task extends PureComponent {
    state = {
        isLoading: true,
        isDeleting: false,
        task: null,
        taskResults: null,
    }

    componentDidMount() {
        this.fetchTask();
    }

    async fetchTask() {
        const [task, taskResults] = await Promise.all([
            API.fetchTask(this.props.taskID),
            API.fetchTaskResults(this.props.taskID),
        ]);

        this.setState({
            isLoading: false,
            task,
            taskResults,
        });
    }

    async handleTaskResult(taskResult) {
        const url = taskResult.url;
        if (!url) {
            return;
        }

        const canOpen = await Linking.canOpenURL(url);
        if (!canOpen) {
            console.error(`Could not open ${url}`);

            return;
        }

        await Linking.openURL(url);

        if (taskResult.acked_at) {
            return;
        }

        await API.ackTaskResult(taskResult.id);
    }

    showTaskDetails() {
        Alert.alert('', JSON.stringify(this.state.task, null, 4), [], { cancelable: true });
    }

    async deleteTask() {
        const promise = new Promise((resolve, reject) => {
            Alert.alert('',
                'Delete the task?',
                [
                    { text: 'Cancel', onPress: reject },
                    { text: 'OK', onPress: resolve }
                ],
                { cancelable: true, onDismiss: reject });
        });

        try {
            await promise;
        } catch (e) {
            return;
        }

        this.setState({
            isDeleting: true,
        });

        try {
            await API.deleteTask(this.state.task.id);
        } catch (error) {
            console.warn(error);

            this.setState({
                isDeleting: false,
            });

            return;
        }

        this.props.goTo('tasks');
    }

    render() {
        let content;
        if (this.state.isLoading) {
            content = this.renderLoading();
        } else {
            content = this.renderLoaded();
        };

        return <>{ content }</>
    };

    renderLoading() {
        return (
            <ActivityIndicator size="large" color="#0000ff" />
        );
    }

    renderLoaded() {
        return <>
            <View style={{ flex: 1 }}>
                { this.state.taskResults.map(this.renderResult.bind(this)) }
            </View>
            <Button
                title="Inspect"
                color="grey"
                onPress={ this.showTaskDetails.bind(this) } />
            <Button
                title="Delete"
                color="red"
                disabled={ this.state.isDeleting }
                onPress={ this.deleteTask.bind(this) } />
        </>
    }

    renderResult(taskResult, i) {
        const style = [styles.taskResult];
        if (i > 0) {
            style.push(styles.taskResultNotFirst);
        }

        return (
            <View key={ taskResult.id }>
                <TouchableNativeFeedback
                    onPress={ this.handleTaskResult.bind(this, taskResult) } >
                    <View style={ style }>
                        <Text>{ taskResult.body }</Text>
                        <Text>{ taskResult.url }</Text>
                    </View>
                </TouchableNativeFeedback>
            </View>
        );
    }
};

const styles = StyleSheet.create({
    taskResult: {
        minHeight: 75,
        padding: 10,
        justifyContent: 'space-around',
    },
    taskResultNotFirst: {
        borderTopWidth: 1
    }
});
