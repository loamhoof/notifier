import React from 'react';
import {
    Text,
    TextInput,
} from 'react-native';

import Time from '../../common/time';
import {
    isStrictlyPositive,
    isTrueish,
} from '../../common/validators';


export default {
    form: {
        description: {
            default: '',
            isValid: isTrueish,
        },
        every: {
            default: '' + 60 * 60 * 24 * 7, // every week
            cast: (interval) => parseInt(interval) * 1000,
            isValid: isStrictlyPositive,
            compute: (interval, isValid) => isValid ? Time.toString(interval / 1000) : '',
        },
    },
    render() {
        return <>
            <Text>Description</Text>
            <TextInput
                value={ this.state.typeForm.description }
                onChangeText={ this.changeTypeFormParam.bind(this, 'description') } />
            <Text>Every</Text>
            <Text>{ this.state.computedTypeForm.every }</Text>
            <TextInput
                keyboardType="number-pad"
                value={ this.state.typeForm.every }
                onChangeText={ this.changeTypeFormParam.bind(this, 'every') } />
        </>
    }
};
