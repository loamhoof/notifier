import React, { PureComponent } from 'react';
import {
    ActivityIndicator,
    Button,
    StyleSheet,
    Text,
    TouchableNativeFeedback,
    View
} from 'react-native';

import API from '../common/api';

export default class Tasks extends PureComponent {
    state = {
        isLoading: true,
        tasks: [],
    };

    componentDidMount() {
        this.fetchTasks();
    }

    async fetchTasks() {
        const tasks = await API.fetchTasks();

        this.setState({
            isLoading: false,
            tasks,
        });
    }

    render() {
        let content;
        if (this.state.isLoading) {
            content = this.renderLoading();
        } else {
            content = this.renderLoaded();
        };

        return <>
            <Button title="New" onPress={ this.props.goTo.bind(this, 'newTask') } />
            { content }
        </>
    }

    renderLoading() {
        return (
            <ActivityIndicator size="large" color="#0000FF" />
        );
    }

    renderLoaded() {
        return this.state.tasks.map(this.renderOne.bind(this));
    }

    renderOne(task, i) {
        const style = [styles.task];
        if (i > 0) {
            style.push(styles.taskNotFirst);
        }

        return (
            <View key={ task.id }>
                <TouchableNativeFeedback
                    onPress={ this.props.goTo.bind(this, 'task', { taskID: task.id }) }>
                    <View style={ style }>
                        <Text>{ task.name }</Text>
                        <Text>{ task.type }</Text>
                    </View>
                </TouchableNativeFeedback>
            </View>
        );
    }
};

const styles = StyleSheet.create({
    task: {
        minHeight: 75,
        padding: 10,
        justifyContent: 'space-around',
    },
    taskNotFirst: {
        borderTopWidth: 1
    }
});
