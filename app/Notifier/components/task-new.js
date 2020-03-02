import React, { PureComponent } from 'react';
import {
    Button,
    Picker,
    Text,
    TextInput,
    View
} from 'react-native';

import API from '../common/api';
import Time from '../common/time';
import {
    isStrictlyPositive,
    isTrueish,
} from '../common/validators';


export default class NewTask extends PureComponent {
    state = {
        form: {},
        castForm: {},
        computedForm: {},
        isValidForm: {},
        typeForm: null,
        castTypeForm: {},
        computedTypeForm: {},
        isValidTypeForm: {},
        isValid: false,
        isSubmitting: false,
    }

    form = {
        name: {
            default: '',
            isValid: isTrueish,
        },
        type: {
            default: null,
            isValid: isTrueish,
        },
    }

    typeForms = {
        rss: {
            interval: {
                default: '' + 60,
                cast: (interval) => parseInt(interval) * 1000,
                isValid: isStrictlyPositive,
                compute: (interval, isValid) => isValid ? Time.toString(interval / 1000) : '',
            },
            feed: {
                default: '',
                isValid: isTrueish,
            },
        },
    }

    constructor(props) {
        super(props);

        const [form, castForm, isValidForm, computedForm] = this.initForm(this.form);
        this.state = {
            ...this.state,
            form, castForm, isValidForm, computedForm,
            isValid: this.isValid(isValidForm, this.state.isValidTypeForm),
        };
    }

    initForm(formDefinition) {
        let form = {};
        let castForm = {};
        let isValidForm = {};
        let computedForm = {};
        for (const [paramKey, param] of Object.entries(formDefinition)) {
            const value = param.default;
            const [castValue, isValidValue, computedValue] = this.computeParam(param, value);

            form[paramKey] = value;
            castForm[paramKey] = castValue;
            isValidForm[paramKey] = isValidValue;
            computedForm[paramKey] = computedValue;
        }

        return [form, castForm, isValidForm, computedForm];
    }

    computeParam(param, newValue) {
        const castValue = param.cast ? param.cast(newValue) : newValue;
        const isValid = param.isValid ? param.isValid(castValue) : true;
        const computedValue = param.compute ? param.compute(castValue, isValid) : undefined;

        return [castValue, isValid, computedValue];
    }

    changeTaskType(newTaskType) {
        this.setState((state) => {
            let typeFormDefinition = {};
            if (newTaskType) {
                typeFormDefinition = this.typeForms[newTaskType];
            }

            const [castTaskType, isValidTaskType, computedTaskType] = this.computeParam(this.form.type, newTaskType);

            const form = { ...state.form, type: newTaskType };
            const castForm = { ...state.castForm, type: castTaskType };
            const isValidForm = { ...state.isValidForm, type: isValidTaskType };
            const computedForm = { ...state.computedForm, type: computedTaskType };

            const typeForms = this.initForm(typeFormDefinition);
            const [typeForm, castTypeForm, isValidTypeForm, computedTypeForm] = typeForms;

            const isValid = this.isValid(isValidForm, isValidTypeForm);

            return {
                form, castForm, computedForm, isValidForm,
                typeForm, castTypeForm, computedTypeForm, isValidTypeForm,
                isValid,
            };
        });
    }

    changeFormParam(paramKey, newValue) {
        this.setState((state) => {
            const [castValue, isValidValue, computedValue] = this.computeParam(this.form[paramKey], newValue);

            const form = { ...state.form, [paramKey]: newValue };
            const castForm = { ...state.castForm, [paramKey]: castValue };
            const isValidForm = { ...state.isValidForm, [paramKey]: isValidValue };
            const computedForm = { ...state.computedForm, [paramKey]: computedValue };

            const isValid = this.isValid(isValidForm, state.isValidTypeForm);

            return {
                form, castForm, isValidForm, computedForm,
                isValid,
            };
        });
    }

    changeTypeFormParam(paramKey, newValue) {
        this.setState((state) => {
            const taskType = state.form.type;
            const paramDefinition = this.typeForms[taskType][paramKey];
            const [castValue, isValidValue, computedValue] = this.computeParam(paramDefinition, newValue);

            const typeForm = { ...state.typeForm, [paramKey]: newValue };
            const castTypeForm = { ...state.castTypeForm, [paramKey]: castValue };
            const isValidTypeForm = { ...state.isValidTypeForm, [paramKey]: isValidValue };
            const computedTypeForm = { ...state.computedTypeForm, [paramKey]: computedValue };

            const isValid = this.isValid(state.isValidForm, isValidTypeForm);

            return {
                typeForm, castTypeForm, isValidTypeForm, computedTypeForm,
                isValid,
            };
        });
    }

    isValid(isValidForm, isValidTypeForm) {
        let isValid = Object.values(isValidForm).every(v => v);
        isValid = isValid && Object.values(isValidTypeForm).every(v => v);

        return isValid;
    }

    async createTask() {
        this.setState({
            isSubmitting: true,
        });

        try {
            await API.createTask({
                ...this.state.castForm,
                config: { ...this.state.castTypeForm },
            });
        } catch (error) {
            console.warn(error);

            this.setState({
                isSubmitting: false,
            });

            return;
        }

        this.props.goTo('tasks');
    }

    // DEV
    componentDidMount() {
        this.changeTaskType('rss');
    }

    render() {
        return <>
            <Button title="Tasks" onPress={ () => this.props.goTo('tasks') } />
            <View>
                <Text>Name</Text>
                <TextInput
                    value={ this.state.form.name }
                    onChangeText={ this.changeFormParam.bind(this, 'name') } />
                <Text>Type</Text>
                <Picker
                    selectedValue={ this.state.form.type }
                    onValueChange={ this.changeTaskType.bind(this) } >
                    <Picker.Item label="" value="" />
                    <Picker.Item label="RSS" value="rss" />
                </Picker>
                { this.renderForm() }
                <Button
                    title="Create"
                    disabled={ this.state.isSubmitting || !this.state.isValid }
                    onPress={ this.createTask.bind(this) } />
            </View>
        </>
    }

    renderForm() {
        switch (this.state.form.type) {
        case 'rss':
            return this.renderRSS();
        }
    }

    renderRSS() {
        return <>
            <Text>Interval</Text>
            <Text>{ this.state.computedTypeForm.interval }</Text>
            <TextInput
                keyboardType="number-pad"
                value={ this.state.typeForm.interval }
                onChangeText={ this.changeTypeFormParam.bind(this, 'interval') } />
            <Text>Feed</Text>
            <TextInput
                value={ this.state.typeForm.feed }
                onChangeText={ this.changeTypeFormParam.bind(this, 'feed') } />
        </>
    }
};
