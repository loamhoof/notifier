import React from 'react';
import {
    Text,
    TextInput,
} from 'react-native';

import {
    isTrueish,
} from '../../common/validators';


export default {
    form: {
        feed: {
            default: '',
            isValid: isTrueish,
        },
    },
    render() {
        return <>
            <Text>Feed</Text>
            <TextInput
                value={ this.state.typeForm.feed }
                onChangeText={ this.changeTypeFormParam.bind(this, 'feed') } />
        </>
    }
};
