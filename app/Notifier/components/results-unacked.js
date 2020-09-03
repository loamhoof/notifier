import React, { PureComponent } from 'react';
import {
    ActivityIndicator,
    Button,
    Linking,
    StyleSheet,
    Text,
    TouchableNativeFeedback,
    View
} from 'react-native';

import API from '../common/api';

export default class UnackedResults extends PureComponent {
    state = {
        isLoading: true,
        taskResults: [],
    };

    componentDidMount() {
        this.fetchAllUnackedTaskResults();
    }

    async fetchAllUnackedTaskResults() {
        const taskResults = await API.fetchAllUnackedTaskResults();

        this.setState({
            isLoading: false,
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

        const resultID = taskResult.id;

        await API.ackTaskResult(resultID);

        this.setState(({ taskResults }) => {
            const taskResultIndex = taskResults.findIndex((tr) => tr.id == resultID);
            if (taskResultIndex == -1)  {
                return;
            }

            taskResults.splice(taskResultIndex, 1);

            return { taskResults: [...taskResults] };
        });
    }

    render() {
        if (this.state.isLoading) {
            return this.renderLoading();
        }

        return this.renderLoaded();
    }

    renderLoading() {
        return (
            <ActivityIndicator size="large" color="#0000FF" />
        );
    }

    renderLoaded() {
        if (this.state.taskResults.length == 0) {
            return this.renderEmpty();
        }

        return this.state.taskResults.map(this.renderOne.bind(this));
    }

    renderEmpty() {
        return (
            <Text>Nothing here.</Text>
        );
    }

    renderOne(taskResult, i) {
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
