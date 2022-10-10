#include <errno.h>
#include <signal.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "mafp_interfaces.h"

#define MAFP_FINGERPRINT_HARDWARE_MODULE_ID  "microarray.fingerprint"
#define DEFAULT_ACTIVE_GROUP  0
#define DEFAULT_STORAGE_DIR  "/var/tmp"

typedef enum fp_action_type {
    ACTION_GET_VERSION = 0,
    ACTION_ENROLL,
    ACTION_VERIFY,
    ACTION_SEARCH,
    ACTION_DELETE,
    ACTION_ENUMERATE,
} fp_action_type_t;

uint8_t process_finish = 0;
fingerprint_device_t *mDevices;

fp_action_type_t getActionType(char* s)
{
    if(!strcmp(s,"enroll")) return ACTION_ENROLL;
    if(!strcmp(s,"verify")) return ACTION_VERIFY;
    if(!strcmp(s,"search")) return ACTION_SEARCH;
    if(!strcmp(s,"delete")) return ACTION_DELETE;
    if(!strcmp(s,"enumerate")) return ACTION_ENUMERATE;
    if(!strcmp(s,"version")) return ACTION_GET_VERSION;
    return -1;
}

void onAcquire(fingerprint_acquired_t *data)
{
    switch(data->acquired_info) {
        case FINGERPRINT_ACQUIRED_GOOD:
            printf("onAcquire: ACQUIRED GOOD\n");
            break;
        case FINGERPRINT_ACQUIRED_PARTIAL:
            printf("onAcquire: ACQUIRED PARTIAL\n");
            break;
         case FINGERPRINT_ACQUIRED_INSUFFICIENT:
            printf("onAcquire: ACQUIRED INSUFFICIENT\n");
            break;
        case FINGERPRINT_ACQUIRED_IMAGER_DIRTY:
            printf("onAcquire: ACQUIRED IMAGER DIRTY\n");
            break;
         case FINGERPRINT_ACQUIRED_TOO_SLOW:
            printf("onAcquire: ACQUIRED TOO SLOW\n");
            break;
        case FINGERPRINT_ACQUIRED_TOO_FAST:
            printf("onAcquire: ACQUIRED TOO FAST\n");
            break;
        case FINGERPRINT_ACQUIRED_BASE_DOWN:
            printf("onAcquire: ACQUIRED DOWN\n");
            break;
        case FINGERPRINT_ACQUIRED_BASE_UP:
            printf("onAcquire: ACQUIRED UP\n");
            break;
        default:
            break;
    }
}

void onEnroll(fingerprint_enroll_t *data)
{
    fingerprint_finger_id_t *finger = &data->finger;
    uint32_t remaining = data->samples_remaining;
    printf("onEnroll: gid %d, fid %d, remain %d\n", finger->gid, finger->fid, remaining);
    if(remaining <= 0) {
        printf("enroll finish\n");
        process_finish = 1;
        mDevices->post_enroll(mDevices);
    }
}

void onRemove(fingerprint_removed_t *data)
{
    fingerprint_finger_id_t *finger = &data->finger;
    printf("onRemove: gid %d, fid %d\n", finger->gid, finger->fid);
    process_finish = 1;
}

void onAuthenticate(fingerprint_authenticated_t *data)
{
    fingerprint_finger_id_t *finger = &data->finger;
    printf("onAuthenticate: gid %d, fid %d\n", finger->gid, finger->fid);
    if(finger->fid) {
        printf("match successfully\n");
    } else {
        printf("No matched\n");
    }
    process_finish = 1;
}

void onEnumerate(fingerprint_enumerated_t *data)
{
    fingerprint_finger_id_t *finger = &data->finger;
    uint32_t remaining = data->remaining_templates;
    printf("onEnumerate: gid %d, fid %d\n", finger->gid, finger->fid);
    process_finish = 1;
}

void onError(fingerprint_error_t data)
{
    switch(data) {
        case FINGERPRINT_ERROR_HW_UNAVAILABLE:
            printf("onError: ERROR_HW_UNAVAILABLE\n");
            break;
        case FINGERPRINT_ERROR_UNABLE_TO_PROCESS:
            printf("onError: RROR UNABLE TO PROCESS\n");
            break;
         case FINGERPRINT_ERROR_TIMEOUT:
            printf("onError: ERROR TIMEOUT\n");
            break;
        case FINGERPRINT_ERROR_NO_SPACE:
            printf("onError: ERROR NO SPACE\n");
            break;
         case FINGERPRINT_ERROR_CANCELED:
            printf("onError: ERROR CANCELED\n");
            break;
        case FINGERPRINT_ERROR_UNABLE_TO_REMOVE:
            printf("onError: ERROR UNABLE TO REMOVE\n");
            break;
        case FINGERPRINT_ERROR_LOCKOUT:
            printf("onError: ERROR LOCKOUT\n");
            break;
        case FINGERPRINT_ERROR_AUTHENTICATED:
            printf("onError: ERROR AUTHENTICATED\n");
            break;
        default:
            break;
    }
}

void fingerprint_hal_notify(const fingerprint_msg_t *msg) {
    fingerprint_msg_type_t type = msg->type;
    switch (type) {
        case FINGERPRINT_ERROR:
            printf("get message:ERROR\n");
            onError(msg->data.error);
            break;
        case FINGERPRINT_ACQUIRED:
            printf("get message:ACQUIRED\n");
            onAcquire(&msg->data.acquired);
            break;
        case FINGERPRINT_TEMPLATE_ENROLLING:
            printf("get message:ENROLLING\n");
            onEnroll(&msg->data.enroll);
            break;
        case FINGERPRINT_TEMPLATE_REMOVED:
            printf("get message:REMOVED\n");
            onRemove(&msg->data.removed);
            break;
        case FINGERPRINT_AUTHENTICATED:
            printf("get message:AUTHENTICATED\n");
            onAuthenticate(&msg->data.authenticated);
            break;
        case FINGERPRINT_TEMPLATE_ENUMERATING:
            printf("get message:ENUMERATING\n");
            onEnumerate(&msg->data.enumerated);
            break;
        default:
          printf("get message unknow!:%d\n", type);
    }
}

void show_menu(int argc) {
    puts("******************** help information *********************");
	puts("[version] show verison information about lib");
	puts("[enroll] enroll finger process");
    puts("[verify] verify finger");
	puts("[search] search finger");
	puts("[delete] delete finger with fid");
	puts("[enumerate] enumerate finger have been enrolled");
	puts("******************** Microarray FP Lib *********************");
	puts("Author:Young date:2022.09.14 version v1.0\n");
}

int32_t main(int argc, char *argv[])
{
    int ret;
    int64_t authenticator_id;

    puts("******************** Microarray Fingerprint Module Test Program *********************");
    if(argc==1) {
        show_menu(argc);
        return 0;
    }

    ret = fingerprint_open(MAFP_FINGERPRINT_HARDWARE_MODULE_ID, &mDevices);
    if(ret || !mDevices) {
        printf("open fingerprint devices failed\n");
        return -1;
    }

    ret = mDevices->set_active_group(mDevices, DEFAULT_ACTIVE_GROUP, DEFAULT_STORAGE_DIR);
    if(ret) {
        printf("set active group failed\n");
        return -1;
    }

    ret = mDevices->set_notify(mDevices, fingerprint_hal_notify);
    if(ret) {
        printf("set notify callback function failed\n");
        return -1;
    }

    fp_action_type_t action = getActionType(argv[1]);
    hw_device_info_t *info = &mDevices->dev_info;
    hw_auth_token_t token = {0};
    switch(action) {
        case ACTION_GET_VERSION:
            printf("tag:%u, api_version:%u, hw_version:%u,id:%s, name:%s, author:%s\n",
              info->tag, info->api_version, info->hw_version, info->id, info->name, info->author);
            break;
        case ACTION_ENROLL:
            mDevices->pre_enroll(mDevices);
            mDevices->enroll(mDevices, &token, DEFAULT_ACTIVE_GROUP, 60);
            printf("process_finish:%d\n", process_finish);
            while(!process_finish)
              sleep(1);
            printf("enroll complete, token info: challenge:%lu, user_id:%lu, authenticator_id:%lu, type:%u\n",
            token.challenge, token.user_id, token.authenticator_id, token.authenticator_type);
            break;
        case ACTION_VERIFY:
            authenticator_id = mDevices->get_authenticator_id(mDevices);
            mDevices->authenticate(mDevices, authenticator_id, DEFAULT_ACTIVE_GROUP);
            while(!process_finish)
              sleep(1);
            break;
        case ACTION_SEARCH:
            authenticator_id = mDevices->get_authenticator_id(mDevices);
            mDevices->authenticate(mDevices, authenticator_id, DEFAULT_ACTIVE_GROUP);
            while(!process_finish)
              sleep(1);
            break;
        case ACTION_DELETE:
            mDevices->remove(mDevices, DEFAULT_ACTIVE_GROUP, 0);
            while(!process_finish)
              sleep(1);
            break;
        case ACTION_ENUMERATE:
            mDevices->enumerate(mDevices);
            while(!process_finish)
              sleep(1);
            break;
        default:
            printf("No action execute!\n");
            break;
    }

    mDevices->close(mDevices);

    return 0;
}
