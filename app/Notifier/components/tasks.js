import React, { PureComponent } from 'react';
import {
    ActivityIndicator,
    Button,
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

    async deleteTask(taskID) {
        try {
            await API.deleteTask(taskID);
        } catch (error) {
            console.warn(error);

            return;
        }

        this.setState((state) => {
            let tasks = state.tasks;
            const taskIndex = tasks.findIndex((t) => t.id == taskID);
            if (taskIndex == -1) {
                return {};
            }

            tasks.splice(taskIndex, 1);

            return {
                tasks: [...tasks]
            };
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
            <ActivityIndicator size="large" color="#0000ff" />
        );
    }

    renderLoaded() {
        return this.state.tasks.map(this.renderOne.bind(this));
    }

    renderOne(task) {
        return (
            <View key={ task.id }>
                <TouchableNativeFeedback
                    onPress={ this.props.goTo.bind(this, 'task', { taskID: task.id }) }>
                    <View>
                        <Text>{ `${task.name} - ${task.type}` }</Text>
                    </View>
                </TouchableNativeFeedback>
                {/*<Button title="Delete" onPress={ this.deleteTask.bind(this, task.id) } />*/}
            </View>
        );
    }
};
