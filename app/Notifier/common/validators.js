export const isStrictlyPositive = (value) => value > 0;
export const isTrueish = (value) => !!value;
export const isRegex = (value) => {
    try {
        new RegExp(value);
    } catch (e) {
        return false;
    }

    return true;
};

export const isOneOf = (enumValues) => (value) => enumValues.includes(value);
export const everyIs = (validator) => (value) => value.every(validator);
export const objectIs = (validatorsMap) => (value) => {
    return Object.entries(validatorsMap).every(([key, validator]) => validator(value[key]));
};
