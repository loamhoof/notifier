import React, { PureComponent } from 'react';
import {
    ActivityIndicator,
    Button,
    Text,
    View
} from 'react-native';

import API from '../common/api';


export default class Task extends PureComponent {
    state = {
        isLoading: true,
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
            <Button title="Tasks" onPress={ () => this.props.goTo('tasks') } />
            <Text>{ JSON.stringify(this.state.task) }</Text>
            <View>
                { this.state.taskResults.map(this.renderResult.bind(this)) }
            </View>
        </>
    }

    renderResult(taskResult) {
        return (
            <View key={ taskResult.id }>
                <Text>{ JSON.stringify(taskResult) }</Text>
            </View>
        );
    }
};
