/*/ Web Code Execution \*/

/*
	@{author}: zirt
 	@{title}: WE
	@{description}: Execute lua scripts from your browser with several different methods for the execution. Uses the long-polling HTTP Method.
*/

const WEB_METHOD = "queue"; /* job method never coming muahhahah */
const SERVER_PORT = 8080; /* when hosting the web server using express */
/*******************************/
const express = require("express");
const bodyParser = require("body-parser");
/*******************************/
const app = express(); app.use(bodyParser.json());
/*******************************/
const scriptQueue = []; /* js dont let me down PLZ */

app.get('/executor', (req, res) => {
	res.sendFile(__dirname + '/executor.html');
});
app.get('/', (req, res) => {
	res.sendFile(__dirname + '/executor.html');
})

if (WEB_METHOD === "queue") {
    app.post('/addqueue', (req, res) => {
        let {
            script
        } = req.body;
        if (script) {
            scriptQueue.push(script);
						console.log(`[WE]: Script received: ${script}`);
            res.status(200).send("[WE]: Script added in queue!");
        } else {
            res.status(400).send("[WE]: message index wasn't found in JSON Body!");
        }
    });

    app.get('/getqueue', (req, res) => {
        if (scriptQueue.length > 0) {
            res.json({
                scriptQueue
            });
						console.log(`[WE]: Successfully sent script queue array!`);
            scriptQueue.length = 0;
        } else {
            res.json({});
        }
    });
		app.get('/clearqueue', (req, res) => {
			scriptQueue.length = 0;
			console.log(`[WE]: Successfully cleared the script queue.`);
			res.status(200).send("[WE]: Script Queue successfully cleared!");
		}); /* Used by the web executor, not the code handler. */

    app.listen(SERVER_PORT);

    /* end */
} else if (WEB_METHOD === "job") {
    /* end */
	/* soon */
} else {
    console.error("[WE]: Invalid web execution method provided!");
}