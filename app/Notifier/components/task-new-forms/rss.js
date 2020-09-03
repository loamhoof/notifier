import React from 'react';
import {
    Image,
    Picker,
    Text,
    TextInput,
    TouchableNativeFeedback,
    View,
} from 'react-native';

import { isTrueish, everyIs, objectIs, isOneOf, isRegex } from '../../common/validators';


const RSSForm = {
    form: {
        feed: {
            default: '',
            isValid: isTrueish,
        },
        filters: {
            default: [],
            isValid: everyIs(objectIs({
                field: isOneOf(['title']),
                pattern: isRegex,
            })),
        }
    },

    addFilter() {
        this.setState(({ typeForm }) => {
            const filters = typeForm.filters;
            filters.push({
                field: 'title',
                pattern: '',
            });

            return { typeForm: { ...typeForm, filters } };
        });
    },

    changeFilter(filterIndex, key, newValue) {
        const filters = [...this.state.typeForm.filters];
        filters[filterIndex] = {
            ...filters[filterIndex],
            [key]: newValue,
        };

        this.changeTypeFormParam('filters', filters);
    },

    deleteFilter(filterIndex) {
        this.setState(({ typeForm }) => {
            const filters = typeForm.filters;
            filters.splice(filterIndex, 1);

            return { typeForm: { ...typeForm, filters } };
        });
    },

    render() {
        return <>
            <Text>Feed</Text>
            <TextInput
                value={ this.state.typeForm.feed }
                onChangeText={ this.changeTypeFormParam.bind(this, 'feed') } />
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
                <Text>Filters</Text>
                <TouchableNativeFeedback onPress={ RSSForm.addFilter.bind(this) }>
                    <View style={{ padding: 10, borderRadius: 22 }}>
                        <Image
                            source={ require('../../static/images/add.png') }
                            style={{ height: 24, width: 24 }} />
                    </View>
                </TouchableNativeFeedback>
            </View>
            { this.state.typeForm.filters.map(RSSForm.renderFilter.bind(this)) }
        </>
    },

    renderFilter(filter, filterIndex) {
        return (
            <View
                key={ `filter-${filterIndex}` }
                style={{ flexDirection: 'row', alignItems: 'center' }}>
                <Picker style={{ width: 100 }}
                    selectedValue={ filter.field }
                    onValueChange={ RSSForm.changeFilter.bind(this, filterIndex, 'field') } >
                    <Picker.Item label="Title" value="title" />
                </Picker>
                <TextInput style={{ flex: 1 }}
                    placeholder="Pattern"
                    value={ filter.pattern }
                    onChangeText={ RSSForm.changeFilter.bind(this, filterIndex, 'pattern') } />
                <TouchableNativeFeedback onPress={ RSSForm.deleteFilter.bind(this, filterIndex) }>
                    <View style={{ padding: 10, borderRadius: 22 }}>
                        <Image
                            source={ require('../../static/images/delete.png') }
                            style={{ height: 24, width: 24 }} />
                    </View>
                </TouchableNativeFeedback>
            </View>
        );
    }
};

export default RSSForm;
