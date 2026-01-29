import { LlamaMobileCapacitorPlugin } from 'llama-mobile-capacitor-plugin';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    LlamaMobileCapacitorPlugin.echo({ value: inputValue })
}
