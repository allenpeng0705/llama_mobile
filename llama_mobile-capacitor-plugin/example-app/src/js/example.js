import { LlamaMobile } from 'capacitor-plugin-llamamobile';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    LlamaMobile.echo({ value: inputValue })
}
