// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

interface ICharacter {
    
    // атака другого персонажа
    function attack(address) external;
    // защита от другого персонажа
    function defend(uint8) external returns(bool);

    // лечить персонажа
    function cure(uint8) external;
    // прокачать урон
    function increaseDamage(uint8) external;
    // прокачать защиту
    function increaseDefense(uint8) external;
    // оживить персонажа
    function reborn() external payable;

    // живой персонаж или нет
    function isAlive() external view returns(bool);
    // информация о текущем персонаже - имя, раса, класс, уровень, очки, жизни, урон, защита, адрес владельца персонажа
    function getInfo()
        external
        view
        returns(string memory, string memory, string memory, uint8, uint8, uint8, uint8, uint8, address);
    // информация о персонаже по адресу - имя, раса, класс, уровень, очки, жизни, урон, защита, адрес владельца персонажа
    function getInfo(address)
        external
        view
        returns(string memory, string memory, string memory, uint8, uint8, uint8, uint8, uint8, address);
    // массив адрессов поверженных персонажей
    function getVictories() external returns(address[] memory);
    // массив адрессов персонажей, от которых потерпел поражение
    function getLosses() external returns(address[] memory);
    // дополнение к 4 задаче
    function sales(uint256, address, bool)external;
    function buy(address)external ;
}

contract Character is ICharacter {

    // характеристики персонажа
    // адрес владелец
    address public owner;
    // имя
    address game;
    string public name;
    // раса
    string public race;
    // класс
    string public class;
    // урон
    uint256 public price;
    bool public issale;
    uint8  public damage;
    // защита
    uint8 public defense;
    // здоровье
    uint8 public health;
    // уровень
    uint8 public level;
    // очки
    uint8 public points;
    
    uint256 lastAttack;
    uint256 lastMove;
    address[] losses;
    address[] victories;

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    modifier alive(){
        require(health > 0);
        _;
    }
    modifier time(){
        require(block.timestamp > lastMove + 8 hours);
        _;
    }
    modifier points_(uint256 _points){
        require(points >=_points);
        _;
    }
    constructor(string memory _name, string memory _race, string memory _class, address _owner)
        payable{
        require(msg.value == 1_000_000, "min 1 mil wei");
        name = _name;
        race = _race;
        class = _class; 
        health = 100;
        damage = 5;
        owner = _owner;
        game = msg.sender;

    }
    function attack(address characterAdr) external  onlyOwner alive time{
        require(ICharacter(characterAdr).isAlive());
        ICharacter(characterAdr).defend(damage);
        if(!ICharacter(characterAdr).isAlive()){
            level ++;
            points += 5;
            victories.push(characterAdr);
        }
        lastAttack = block.timestamp;
    }
    function defend(uint8 _damage) external returns(bool) {
        require(block.timestamp > lastAttack + 8 hours);
        require((msg.sender).codehash == address(this).codehash);
        if(health < _damage || defense == 0){ 
            (,,,,,,,,address _attOwner) = ICharacter(msg.sender).getInfo();
            payable (_attOwner).transfer(address(this).balance);
            health == 0;
            losses.push(msg.sender);
            lastAttack = block.timestamp;
            return health == 0;
        }    
        _damage -= defense;
        health -= _damage;
        lastMove = block.timestamp;
        return false;
        
    }
    function cure(uint8 _points) external  onlyOwner time points_(_points){
        points -= _points;
        health += 5 * _points;
        lastMove = block.timestamp;
    }
    function increaseDamage(uint8 _points) external onlyOwner time points_(_points){
        points -= _points;
        damage += _points;
        lastMove = block.timestamp;
    }
    function increaseDefense(uint8 _points) external onlyOwner time points_(_points){
        points -= _points;
        defense += _points;
    }
    function reborn() external payable onlyOwner{
        
        require(health == 0);
        require(msg.value == 1_000_000);
        health = 100;
    }
    function isAlive() external view returns(bool) {
        return  health > 0;
    }
    function getInfo()
        external
        view
        returns(string memory, string memory, string memory, 
                uint8, uint8, uint8, uint8, uint8, address) {
        return  (name, race, class, 
                damage, defense, health, 
                level, points, owner);
    }
    function getInfo(address anotherCharacter)
        external
        view
        returns(string memory, string memory, string memory, 
                uint8, uint8, uint8, uint8, uint8, address) {
        
        return ICharacter(anotherCharacter).getInfo(); 
        }
    function getVictories() external view returns(address[] memory) {
        return victories;
    }
    function getLosses() external view returns(address[] memory) {
        return losses;
    }
    // дополнение к 4 задаче
    function sales(uint256 _price, address adr, bool _issale)public {
        require(msg.sender == game && adr == owner);
        price = _price;
        issale = _issale;
    }
    function buy(address _newOwner)public {
        require(msg.sender == game && issale);
        owner = _newOwner;
    }
}
contract Game{ 
    address[] public characters;
    function creatCharacter(
        string memory _name, 
        string memory _race, 
        string memory _class)public payable returns(address)
        {
        require(msg.value == 1000000);
        characters.push(address(new Character{value: msg.value}(_name, _race, _class, msg.sender)));
        return msg.sender;
    }
    function saleCharacter(uint256 index, uint256 price, bool issale)public{
        ICharacter(characters[index]).sales(price, msg.sender, issale);
    }
    function buyCharacter(uint256 index)public payable{
        require(Character(characters[index]).issale());
        require(msg.value == Character(characters[index]).price());
        (,,,,,,,, address owner_) = ICharacter(characters[index]).getInfo();
        payable(owner_).transfer(msg.value);
        Character(characters[index]).buy(msg.sender);
    }
}
