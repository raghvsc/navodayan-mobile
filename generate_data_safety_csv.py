import csv
import sys

# List of collected data types:
COLLECTED_TYPES = {
    'PSL_NAME',
    'PSL_EMAIL',
    'PSL_USER_ACCOUNT',
    'PSL_ADDRESS',
    'PSL_PHONE',
    'PSL_OTHER_MESSAGES',
    'PSL_PHOTOS',
    'PSL_CRASH_LOGS',
    'PSL_PERFORMANCE_DIAGNOSTICS',
    'PSL_USER_INTERACTION',
    'PSL_USER_GENERATED_CONTENT',
    'PSL_DEVICE_ID',
}

REQUIRED_DATA_TYPES = {
    'PSL_NAME',
    'PSL_EMAIL',
    'PSL_USER_ACCOUNT',
    'PSL_CRASH_LOGS',
    'PSL_PERFORMANCE_DIAGNOSTICS',
    'PSL_DEVICE_ID',
}

# Purposes per data type:
PURPOSES_MAP = {
    'PSL_NAME': {'PSL_APP_FUNCTIONALITY', 'PSL_ACCOUNT_MANAGEMENT', 'PSL_FRAUD_PREVENTION_SECURITY'},
    'PSL_EMAIL': {'PSL_APP_FUNCTIONALITY', 'PSL_ACCOUNT_MANAGEMENT', 'PSL_FRAUD_PREVENTION_SECURITY'},
    'PSL_USER_ACCOUNT': {'PSL_APP_FUNCTIONALITY', 'PSL_ACCOUNT_MANAGEMENT', 'PSL_FRAUD_PREVENTION_SECURITY'},
    'PSL_ADDRESS': {'PSL_APP_FUNCTIONALITY', 'PSL_PERSONALIZATION'},
    'PSL_PHONE': {'PSL_APP_FUNCTIONALITY', 'PSL_PERSONALIZATION'},
    'PSL_OTHER_MESSAGES': {'PSL_APP_FUNCTIONALITY'},
    'PSL_PHOTOS': {'PSL_APP_FUNCTIONALITY', 'PSL_PERSONALIZATION'},
    'PSL_CRASH_LOGS': {'PSL_APP_FUNCTIONALITY', 'PSL_ANALYTICS'},
    'PSL_PERFORMANCE_DIAGNOSTICS': {'PSL_APP_FUNCTIONALITY', 'PSL_ANALYTICS'},
    'PSL_USER_INTERACTION': {'PSL_APP_FUNCTIONALITY', 'PSL_ANALYTICS'},
    'PSL_USER_GENERATED_CONTENT': {'PSL_APP_FUNCTIONALITY', 'PSL_ACCOUNT_MANAGEMENT'},
    'PSL_DEVICE_ID': {'PSL_APP_FUNCTIONALITY', 'PSL_ANALYTICS', 'PSL_FRAUD_PREVENTION_SECURITY'},
}

def generate_csv(input_path, output_path):
    with open(input_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        rows = list(reader)

    out_rows = []
    for row in rows:
        if len(row) < 5:
            continue
        qid, rid, val, req, label = row[0].strip(), row[1].strip(), row[2].strip(), row[3].strip(), row[4].strip()

        new_val = ""

        # Top-level general questions
        if qid == "PSL_DATA_COLLECTION_COLLECTS_PERSONAL_DATA":
            new_val = "true"
        elif qid == "PSL_DATA_COLLECTION_ENCRYPTED_IN_TRANSIT":
            new_val = "true"
        elif qid == "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS":
            if rid == "PSL_ACM_USER_ID_PASSWORD":
                new_val = "true"
            else:
                new_val = ""
        elif qid == "PSL_ACCOUNT_DELETION_URL":
            new_val = "https://www.navodayan.org/settings"
        elif qid == "PSL_SUPPORT_DATA_DELETION_BY_USER":
            if rid == "DATA_DELETION_YES":
                new_val = "true"
            else:
                new_val = ""
        elif qid == "PSL_DATA_DELETION_URL":
            new_val = "https://www.navodayan.org/settings"
        elif qid in (
            "PSL_DATA_COLLECTION_COMPLIES_FAMILY_POLICY",
            "PSL_INDEPENDENTLY_VALIDATED",
            "PSL_UPI_BADGE_OPT_IN",
            "PSL_ACM_SPECIFY",
            "PSL_HAS_OUTSIDE_APP_ACCOUNTS",
            "PSL_OUTSIDE_APP_ACCOUNT_TYPES",
            "PSL_OUTSIDE_APP_ACCOUNT_TYPE_SPECIFY",
        ):
            new_val = ""
        
        # Data types checkboxes
        elif qid.startswith("PSL_DATA_TYPES_"):
            if rid in COLLECTED_TYPES:
                new_val = "true"
            else:
                new_val = ""

        # Detailed usage responses
        elif qid.startswith("PSL_DATA_USAGE_RESPONSES:"):
            parts = qid.split(":")
            dtype = parts[1]
            qsub = parts[2]

            if dtype in COLLECTED_TYPES:
                if qsub == "PSL_DATA_USAGE_COLLECTION_AND_SHARING":
                    if rid == "PSL_DATA_USAGE_ONLY_COLLECTED":
                        new_val = "true"
                    else:
                        new_val = ""
                elif qsub == "PSL_DATA_USAGE_EPHEMERAL":
                    new_val = "false"
                elif qsub == "DATA_USAGE_USER_CONTROL":
                    if dtype in REQUIRED_DATA_TYPES:
                        if rid == "PSL_DATA_USAGE_USER_CONTROL_REQUIRED":
                            new_val = "true"
                        else:
                            new_val = ""
                    else:
                        if rid == "PSL_DATA_USAGE_USER_CONTROL_OPTIONAL":
                            new_val = "true"
                        else:
                            new_val = ""
                elif qsub == "DATA_USAGE_COLLECTION_PURPOSE":
                    allowed_purposes = PURPOSES_MAP.get(dtype, set())
                    if rid in allowed_purposes:
                        new_val = "true"
                    else:
                        new_val = ""
                elif qsub == "DATA_USAGE_SHARING_PURPOSE":
                    # Data is NEVER shared with third parties
                    new_val = ""
            else:
                # Not collected
                new_val = ""
        else:
            new_val = val

        out_rows.append([qid, rid, new_val, req, label])

    with open(output_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(out_rows)

    print(f"Generated {len(out_rows)} rows into {output_path}")

if __name__ == "__main__":
    generate_csv(sys.argv[1], sys.argv[2])
