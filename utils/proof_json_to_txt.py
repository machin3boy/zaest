import json

if __name__=="__main__":
    proof_json_file = open("proof.json", "r")
    j = json.load(proof_json_file)
    proof_json_file.close()
    a = j['proof']['a']
    b = j['proof']['b']
    c = j['proof']['c']
    i = j['inputs']
    result = str("[")+str(a)+","+str(b)+","+str(c)+"],"+str(i)
    result = result.replace("\"", "")
    result = result.replace("\'", "")
    proof_txt_file = open("proof_for_solidity.txt", "w")
    proof_txt_file.write(result)
    proof_txt_file.close()


