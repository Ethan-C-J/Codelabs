/**
 * @license
 * Copyright 2018 Google LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * =============================================================================
 */

// const { resourceLimits } = require("worker_threads");
import * as DICT from './dictionary.js';
const ENCODING_LEN = 20

function tokenize(wordArr) {

    let retArr = [DICT.START];

    for (var i = 0; i < wordArr.length; i++) {
        let encoding = DICT.LOOKUP[wordArr[i]];
        retArr.push(encoding === undefined ? DICT.UNKNOWN : encoding);
    }

    while (i < ENCODING_LEN-1) {
        retArr.push(DICT.PAD);
        i++;
    }

    console.log([retArr]);

    return tf.tensor([retArr]);

}

// const status = document.getElementById('status');
// status.innerHTML = 'Loaded TensorFlow.js - version: ' + tf.version.tfjs;

const POST_COMMENT_BTN = document.getElementById('post');
const COMMENT_TXT = document.getElementById('comment');
const COMMENT_LIST = document.getElementById('commentsList');

const PROCESSING_CLASS = 'Processing';

var currentUsername = 'anonymous';

function handleCommentPost() {
    if (!POST_COMMENT_BTN.classList.contains(PROCESSING_CLASS)) {
        POST_COMMENT_BTN.classList.add(PROCESSING_CLASS);
        COMMENT_TXT.classList.add(PROCESSING_CLASS);
        COMMENT_LIST.classList.add(PROCESSING_CLASS);

        let currComment = COMMENT_TXT.innerText;
        let lowerArr = currComment.toLowerCase().replace(/[^\w\s]/g, ' ').split(' ');

        let li = document.createElement('li');

        loadAndPredict(tokenize(lowerArr), li).then(() => {
            POST_COMMENT_BTN.classList.remove(PROCESSING_CLASS);
            COMMENT_TXT.classList.remove(PROCESSING_CLASS);

            let p = document.createElement('p');
            p.innerText = COMMENT_TXT.innerText;

            let spanName = document.createElement('span');
            spanName.setAttribute('class', 'username')
            spanName.innerText = currentUsername;

            let spanDate = document.createElement('span');
            spanDate.setAttribute('class', 'timestamp');
            let curDate = new Date();
            spanDate.innerHTML = curDate.toLocaleString();

            li.appendChild(spanName);
            li.appendChild(spanDate);
            li.appendChild(p);
            COMMENT_LIST.prepend(li);

            COMMENT_TXT.innerText = "";
        });
   }
}

POST_COMMENT_BTN.addEventListener('click', handleCommentPost);


const MODEL_JSON = 'model.json';

const SPAM_THRESH = 0.75;
var MODEL = undefined;

async function loadAndPredict(inputTensor, domComment) {
    if (MODEL == undefined) {
        MODEL = await tf.loadLayersModel(MODEL_JSON);
    }

    var res = await MODEL.predict(inputTensor);
    res.print();

    res.data().then(dataArr => {
        if (dataArray[1] > SPAM_THRESHOLD) {
            domComment.classList.add('spam');
        } else {
            socket.emit('comment', {
              username: currentUserName,
              timestamp: domComment.querySelectorAll('span')[1].innerText,
              comment: domComment.querySelectorAll('p')[0].innerText
            });
        }
    })
}

var socket = io.connect();

function handleRemoteComments(data) {

    // Render a new comment to DOM from a remote client.
    let li = document.createElement('li');
    let p = document.createElement('p');
    p.innerText = data.comment;

    let spanName = document.createElement('span');
    spanName.setAttribute('class', 'username');
    spanName.innerText = data.username;

    let spanDate = document.createElement('span');
    spanDate.setAttribute('class', 'timestamp');
    spanDate.innerText = data.timestamp;

    li.appendChild(spanName);
    li.appendChild(spanDate);
    li.appendChild(p);
    
    COMMENTS_LIST.prepend(li);

}

socket.on('remoteComment', handleRemoteComments);
