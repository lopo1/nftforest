pragma solidity >=0.4.22 <0.9.0;

contract InfoContract {
    string name;
    uint  age;
    
    function setInfo(string calldata _name, uint _age) public {
        name = _name;
        age = _age;
    }
    function getInfo() public view returns(string memory, uint) {
        return (name, age);
    }
    
}
