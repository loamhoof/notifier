import React, { PureComponent } from 'react';

import Task from './components/task';
import Tasks from './components/tasks';
import NewTask from './components/task-new';

const ROUTER = {
    task: Task,
    tasks: Tasks,
    newTask: NewTask,
};

export default class App extends PureComponent {
    state = {
        location: 'tasks',
        locationParams: {},
    };

    goTo(newLocation, newLocationParams={}) {
        this.setState((previousState) => ({
            ...previousState,
            location: newLocation,
            locationParams: newLocationParams,
        }));
    }

    render() {
        return <>
            { React.createElement(ROUTER[this.state.location], {
                goTo: this.goTo.bind(this),
                ...this.state.locationParams})
            }
        </>
    }
};
