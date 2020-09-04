import React, { PureComponent } from 'react';
import {
    Button,
    Image,
    Picker,
    StyleSheet,
    Text,
    TextInput,
    TouchableNativeFeedback,
    View
} from 'react-native';

import API from '../common/api';
import { isTrueish, everyIs, objectIs, isOneOf, isRegex } from '../common/validators';

import ReminderForm from './task-new-forms/reminder.js';
import RSSForm from './task-new-forms/rss.js';
import SwitchDiscountForm from './task-new-forms/switch_discount.js';


export default class NewTask extends PureComponent {
    DEFAULT_TASK_TYPE = 'rss';

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
        patches: {
            default: [],
            isValid: everyIs(objectIs({
                field: isOneOf(['body', 'url']),
                pattern: isRegex,
            })),
        }
    }

    typeForms = {
        // reminder: ReminderForm.form,
        rss: RSSForm.form,
        switch_discount: SwitchDiscountForm.form,
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

    addPatch() {
        const patches = this.state.form.patches;
        patches.push({
            field: 'url',
            pattern: '',
            replacement: '',
        });

        this.changeFormParam('patches', patches);
    }

    changePatch(patchIndex, key, newValue) {
        const patches = [...this.state.form.patches];
        patches[patchIndex] = {
            ...patches[patchIndex],
            [key]: newValue,
        };

        this.changeFormParam('patches', patches);
    }

    deletePatch(patchIndex) {
        const patches = this.state.form.patches;
        patches.splice(patchIndex, 1);

        this.changeFormParam('patches', patches);
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
                config: { patches: this.state.castForm.patches, ...this.state.castTypeForm },
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

    componentDidMount() {
        this.changeTaskType(this.DEFAULT_TASK_TYPE);
    }

    render() {
        return <>
            <View style={{ flex: 1 }}>
                <Text>Name</Text>
                <TextInput
                    value={ this.state.form.name }
                    onChangeText={ this.changeFormParam.bind(this, 'name') } />
                <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Text>Patches</Text>
                    <TouchableNativeFeedback onPress={ this.addPatch.bind(this) }>
                        <View style={{ padding: 10, borderRadius: 22 }}>
                            <Image
                                source={ require('../static/images/add.png') }
                                style={{ height: 24, width: 24 }} />
                        </View>
                    </TouchableNativeFeedback>
                </View>
                { this.state.form.patches.map(this.renderPatch.bind(this)) }
                <Text>Type</Text>
                <Picker
                    selectedValue={ this.state.form.type }
                    onValueChange={ this.changeTaskType.bind(this) } >
                    <Picker.Item label="" value="" />
                    {/* <Picker.Item label="Reminder" value="reminder" /> */}
                    <Picker.Item label="RSS" value="rss" />
                    {<Picker.Item label="Switch Discount" value="switch_discount" />}
                </Picker>
                { this.renderForm() }
            </View>
            <Button
                title="Create"
                disabled={ this.state.isSubmitting || !this.state.isValid }
                onPress={ this.createTask.bind(this) } />
        </>;
    }

    renderForm() {
        switch (this.state.form.type) {
        case 'reminder':
            return ReminderForm.render.apply(this);
        case 'rss':
            return RSSForm.render.apply(this);
        case 'switch_discount':
            return SwitchDiscountForm.render.apply(this);
        }
    }

    renderPatch(patch, patchIndex) {
        return (
            <View
                key={ `patch-${patchIndex}` }
                style={{ flexDirection: 'row', alignItems: 'center' }}>
                <Picker style={{ width: 100 }}
                    selectedValue={ patch.field }
                    onValueChange={ this.changePatch.bind(this, patchIndex, 'field') } >
                    <Picker.Item label="Body" value="body" />
                    <Picker.Item label="URL" value="url" />
                </Picker>
                <TextInput style={{ flex: 1 }}
                    placeholder="Pattern"
                    value={ patch.pattern }
                    onChangeText={ this.changePatch.bind(this, patchIndex, 'pattern') } />
                <TextInput style={{ flex: 1 }}
                    placeholder="Replace with"
                    value={ patch.replacement }
                    onChangeText={ this.changePatch.bind(this, patchIndex, 'replacement') } />
                <TouchableNativeFeedback onPress={ this.deletePatch.bind(this, patchIndex) }>
                    <View style={{ padding: 10, borderRadius: 22 }}>
                        <Image
                            source={ require('../static/images/delete.png') }
                            style={{ height: 24, width: 24 }} />
                    </View>
                </TouchableNativeFeedback>
            </View>
        );
    }
};

const styles = StyleSheet.create({});
