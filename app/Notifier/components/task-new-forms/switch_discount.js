import React from 'react';
import {
    Picker,
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
        id: {
            default: '',
            cast: (id) => parseInt(id),
            isValid: isStrictlyPositive,
        },
        country: {
            default: 'FR',
            isValid: isTrueish,
        },
        link: {
            default: '',
            isValid: isTrueish,
        },
    },
    render() {
        return <>
            <Text>ID</Text>
            <TextInput
                value={ this.state.typeForm.id }
                onChangeText={ this.changeTypeFormParam.bind(this, 'id') } />
            <Text>Country</Text>
            <Picker
                selectedValue={ this.state.typeForm.country }
                onValueChange={ this.changeTypeFormParam.bind(this, 'country') } >
                <Picker.Item label="France" value="FR" />
                <Picker.Item label="Japan" value="JP" />
            </Picker>
            <Text>Link</Text>
            <TextInput
                value={ this.state.typeForm.link }
                onChangeText={ this.changeTypeFormParam.bind(this, 'link') } />
        </>
    }
};
