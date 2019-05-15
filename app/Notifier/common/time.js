const SECOND = 1;
const MINUTE = SECOND * 60;
const HOUR = MINUTE * 60;
const DAY = HOUR * 24;

export default {
    toString(duration) {
        const days = Math.floor(duration / DAY);
        duration -= days * DAY;
        const hours = Math.floor(duration / HOUR);
        duration -= hours * HOUR;
        const minutes = Math.floor(duration / MINUTE);
        duration -= minutes * MINUTE;
        const seconds = Math.round(duration / SECOND);

        let str = '';
        str += days ? days + 'd' : '';
        str += hours ? hours + 'h' : '';
        str += minutes ? minutes + 'm' : '';
        str += seconds ? seconds + 's' : '';

        return str;
    }
}
