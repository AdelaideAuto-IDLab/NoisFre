
#include <stdint.h>
#include <string.h>
#include "nrf_gpio.h"
#include "our_service.h"
#include "ble_srv_common.h"
#include "app_error.h"
#include "SEGGER_RTT.h"
#include "boards.h"

// ALREADY_DONE_FOR_YOU: Declaration of a function that will take care of some housekeeping of ble connections related to our service and characteristic
void ble_our_service_on_ble_evt(ble_evt_t const * p_ble_evt, void * p_context)
{
  	ble_os_t * p_our_service =(ble_os_t *) p_context;  
		// OUR_JOB: Step 3.D Implement switch case handling BLE events related to our service. 
		switch (p_ble_evt->header.evt_id)
		{
    case BLE_GAP_EVT_CONNECTED:
        p_our_service->conn_handle = p_ble_evt->evt.gap_evt.conn_handle;
        break;
    case BLE_GAP_EVT_DISCONNECTED:
        p_our_service->conn_handle = BLE_CONN_HANDLE_INVALID;
        break;
    default:
        // No implementation needed.
        break;
		}
	
}

/**@brief Function for adding our new characterstic to "Our service" that we initiated in the previous tutorial. 
 *
 * @param[in]   p_our_service        Our Service structure.
 *
 */
static uint32_t our_char_add(ble_os_t * p_our_service)
{
    // OUR_JOB: Step 2.A, Add a custom characteristic UUID
		uint32_t            err_code;
		ble_uuid_t          char_uuid;
		ble_uuid128_t       base_uuid = BLE_UUID_OUR_BASE_UUID;
		err_code = sd_ble_uuid_vs_add(&base_uuid, &char_uuid.type);
		APP_ERROR_CHECK(err_code);  
    ble_gatts_char_md_t char_md;
    ble_gatts_attr_md_t attr_md;
    ble_gatts_attr_t    attr_char_value;
		
		/////////////////////////////////command characteritic/////////////////////////////////////////
		ble_uuid_t          char_cmd_uuid;
		char_cmd_uuid.uuid      = CHAR_UUID_CMD;
		err_code = sd_ble_uuid_vs_add(&base_uuid, &char_cmd_uuid.type);
		APP_ERROR_CHECK(err_code);  
    memset(&char_md, 0, sizeof(char_md));
		char_md.char_props.read = 1;
		char_md.char_props.write = 1;
		memset(&attr_md, 0, sizeof(attr_md));
		attr_md.vloc        = BLE_GATTS_VLOC_STACK;
		BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.read_perm);
		BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.write_perm);
		memset(&attr_char_value, 0, sizeof(attr_char_value));    
		attr_char_value.p_uuid      = &char_cmd_uuid;
		attr_char_value.p_attr_md   = &attr_md;
		attr_char_value.max_len     = 1;
		attr_char_value.init_len    = 1;
		uint8_t cmd0[1] 						= {0x00};
		attr_char_value.p_value     = cmd0;
		err_code = sd_ble_gatts_characteristic_add(p_our_service->service_handle,
                                   &char_md,
                                   &attr_char_value,
                                   &p_our_service->CMD_handles);
		APP_ERROR_CHECK(err_code);
		
		/////////////////////////////////status characteritic/////////////////////////////////////////
		ble_uuid_t          status_sat_uuid;
		status_sat_uuid.uuid      = CHAR_UUID_STA;
		err_code = sd_ble_uuid_vs_add(&base_uuid, &status_sat_uuid.type);
		APP_ERROR_CHECK(err_code);  
    memset(&char_md, 0, sizeof(char_md));
		char_md.char_props.read = 1;
		memset(&attr_md, 0, sizeof(attr_md));
		attr_md.vloc        = BLE_GATTS_VLOC_STACK;
		BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.read_perm);
		memset(&attr_char_value, 0, sizeof(attr_char_value));    
		attr_char_value.p_uuid      = &status_sat_uuid;
		attr_char_value.p_attr_md   = &attr_md;
		attr_char_value.max_len     = 1;
		attr_char_value.init_len    = 1;
		uint8_t sat0[1] 						= {0x00};
		attr_char_value.p_value     = sat0;
		err_code = sd_ble_gatts_characteristic_add(p_our_service->service_handle,
                                   &char_md,
                                   &attr_char_value,
                                   &p_our_service->SAT_handles);
		APP_ERROR_CHECK(err_code);
		
		/////////////////////////////////challenge characteritic/////////////////////////////////////////
		ble_uuid_t          status_cha_uuid;
		status_cha_uuid.uuid      = CHAR_UUID_CHA;
		err_code = sd_ble_uuid_vs_add(&base_uuid, &status_cha_uuid.type);
		APP_ERROR_CHECK(err_code);  
    memset(&char_md, 0, sizeof(char_md));
		char_md.char_props.read = 1;
		char_md.char_props.write = 1;
		memset(&attr_md, 0, sizeof(attr_md));
		attr_md.vloc        = BLE_GATTS_VLOC_STACK;
		BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.read_perm);
		BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.write_perm);
		memset(&attr_char_value, 0, sizeof(attr_char_value));    
		attr_char_value.p_uuid      = &status_cha_uuid;
		attr_char_value.p_attr_md   = &attr_md;
		attr_char_value.max_len     = 16;
		attr_char_value.init_len    = 16;
		uint8_t cha0[16] 						= {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
																	 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
		attr_char_value.p_value     = cha0;
		err_code = sd_ble_gatts_characteristic_add(p_our_service->service_handle,
                                   &char_md,
                                   &attr_char_value,
                                   &p_our_service->CHA_handles);
		APP_ERROR_CHECK(err_code);
																	 
		/////////////////////////////////address characteritic/////////////////////////////////////////
		ble_uuid_t          status_add_uuid;
		status_add_uuid.uuid      = CHAR_UUID_ADD;
		err_code = sd_ble_uuid_vs_add(&base_uuid, &status_add_uuid.type);
		APP_ERROR_CHECK(err_code);  
    memset(&char_md, 0, sizeof(char_md));
		char_md.char_props.read = 1;
		char_md.char_props.write = 1;
		memset(&attr_md, 0, sizeof(attr_md));
		attr_md.vloc        = BLE_GATTS_VLOC_STACK;
		BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.read_perm);
		BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.write_perm);
		memset(&attr_char_value, 0, sizeof(attr_char_value));    
		attr_char_value.p_uuid      = &status_add_uuid;
		attr_char_value.p_attr_md   = &attr_md;
		attr_char_value.max_len     = 4;
		attr_char_value.init_len    = 4;
		uint8_t add0[4] 						= {0x00,0x00,0x00,0x00};
		attr_char_value.p_value     = add0;
		err_code = sd_ble_gatts_characteristic_add(p_our_service->service_handle,
                                   &char_md,
                                   &attr_char_value,
                                   &p_our_service->ADD_handles);
		APP_ERROR_CHECK(err_code);
		
		/////////////////////////////////length characteritic/////////////////////////////////////////
		ble_uuid_t          status_len_uuid;
		status_len_uuid.uuid      = CHAR_UUID_LEN;
		err_code = sd_ble_uuid_vs_add(&base_uuid, &status_len_uuid.type);
		APP_ERROR_CHECK(err_code);  
    memset(&char_md, 0, sizeof(char_md));
		char_md.char_props.read = 1;
		char_md.char_props.write = 1;
		memset(&attr_md, 0, sizeof(attr_md));
		attr_md.vloc        = BLE_GATTS_VLOC_STACK;
		BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.read_perm);
		BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.write_perm);
		memset(&attr_char_value, 0, sizeof(attr_char_value));    
		attr_char_value.p_uuid      = &status_len_uuid;
		attr_char_value.p_attr_md   = &attr_md;
		attr_char_value.max_len     = 4;
		attr_char_value.init_len    = 4;
		uint8_t len0[4] 						= {0x00,0x00,0x00,0x00};
		attr_char_value.p_value     = len0;
		err_code = sd_ble_gatts_characteristic_add(p_our_service->service_handle,
                                   &char_md,
                                   &attr_char_value,
                                   &p_our_service->LEN_handles);
		APP_ERROR_CHECK(err_code);
		
		/////////////////////////////////response characteritic/////////////////////////////////////////
		ble_uuid_t          status_rep_uuid;
		status_rep_uuid.uuid      = CHAR_UUID_REP;
		err_code = sd_ble_uuid_vs_add(&base_uuid, &status_rep_uuid.type);
		APP_ERROR_CHECK(err_code);  
    memset(&char_md, 0, sizeof(char_md));
		char_md.char_props.read = 1;
		memset(&attr_md, 0, sizeof(attr_md));
		attr_md.vloc        = BLE_GATTS_VLOC_STACK;
		BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.read_perm);
		memset(&attr_char_value, 0, sizeof(attr_char_value));    
		attr_char_value.p_uuid      = &status_rep_uuid;
		attr_char_value.p_attr_md   = &attr_md;
		attr_char_value.max_len     = 16;
		attr_char_value.init_len    = 16;
		uint8_t rep0[16] 						= {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
																	 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
		attr_char_value.p_value     = rep0;
		err_code = sd_ble_gatts_characteristic_add(p_our_service->service_handle,
                                   &char_md,
                                   &attr_char_value,
                                   &p_our_service->REP_handles);
		APP_ERROR_CHECK(err_code);

    return NRF_SUCCESS;
}


/**@brief Function for initiating our new service.
 *
 * @param[in]   p_our_service        Our Service structure.
 *
 */
void our_service_init(ble_os_t * p_our_service)
{
    uint32_t   err_code; // Variable to hold return codes from library and softdevice functions

    // FROM_SERVICE_TUTORIAL: Declare 16-bit service and 128-bit base UUIDs and add them to the BLE stack
    ble_uuid_t        service_uuid;
    ble_uuid128_t     base_uuid = BLE_UUID_OUR_BASE_UUID;
    service_uuid.uuid = BLE_UUID_OUR_SERVICE_UUID;
    err_code = sd_ble_uuid_vs_add(&base_uuid, &service_uuid.type);
    APP_ERROR_CHECK(err_code);    
    
    // OUR_JOB: Step 3.B, Set our service connection handle to default value. I.e. an invalid handle since we are not yet in a connection.
		p_our_service->conn_handle = BLE_CONN_HANDLE_INVALID;

    // FROM_SERVICE_TUTORIAL: Add our service
		err_code = sd_ble_gatts_service_add(BLE_GATTS_SRVC_TYPE_PRIMARY,
                                        &service_uuid,
                                        &p_our_service->service_handle);
    
    APP_ERROR_CHECK(err_code);
    
    // OUR_JOB: Call the function our_char_add() to add our new characteristic to the service. 
    our_char_add(p_our_service);
}
