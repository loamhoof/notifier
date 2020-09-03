export const getPath = (path, value) => {
    path = Array.isArray(path) ? path : [path];

    return path.reduce((value, key) => value[key], value);
};
