// contracts/DungeonsAndDragonsCharacter.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;
import "../simpleVrf/RandomNumberSampleVRF.sol";
import "../simpleVrf/Ownable.sol";
import "../bac002/BAC002.sol";



contract CatBlindbox is BAC002, Ownable {
    using SafeMath for uint256;
    event ResultOfNewBlindboxCat(address sender,string catName,bytes32 requestId);
    event SurpriseCat(bytes32 requestId,string name,uint8 genes,uint256 birthTime,address owner,string images);
//American Shorthair 美短   British Shorthair  英短   Japanese Bobtail 日本短尾猫   Chinese Orange 中华橘猫    Russian Blue 俄罗斯蓝猫    Persian 波斯猫   Ragdoll 布偶猫
    enum CatSeries{ American_Shorthair, British_Shorthair, Japanese_Bobtail, Chinese_Orange, Russian_Blue, Persian, Ragdoll }

    string[7] catsNameDescription = ["American Shorthair", "British Shorthair", "Japanese Bobtail", "Chinese Orange", "Russian Blue", "Persian", "Ragdoll"];

    string[] catImagesUri=["https://pic1.zhimg.com/80/v2-33f59a4343abb6a49b352789377ff5d8_1440w.jpg",
                          "https://pic2.zhimg.com/80/v2-6838d36654876924d75e8cc11545399d_1440w.jpg",
                          "https://pic1.zhimg.com/80/v2-25e8bb0321b78da95990bcdedb692c0c_1440w.jpg",
                            "https://pic1.zhimg.com/v2-82c6c9ea312eb5eeb93d7f53c8e3259a_1440w.jpg",
                            "https://pic1.zhimg.com/80/v2-ce3a26ff6f96c222a9ee93d8179328dc_1440w.jpg",
                            "https://pic4.zhimg.com/80/v2-7a4f80d774519b1cf4be4bcfd5641427_1440w.jpg",
                            "https://pic1.zhimg.com/80/v2-f8d012397a26872df456291ae1772b58_1440w.jpg"];
    struct Cat {
        string name;
        uint8 genes;
        uint256 birthTime;
        address owner;
        string images;
    }

    Cat[] public cats;
    mapping(bytes32 => string)  requestToCatName;
    mapping(bytes32 => address) requestToSender;
    RandomNumberSampleVRF private oracle;

    constructor(address randomOracle) public BAC002("CatBlindBoxSeries", "Cat"){
        oracle = RandomNumberSampleVRF(randomOracle);
    }

    function requestNewBlindboxCat(
        uint256 userProvidedSeed,
        string  name
    ) public returns (bytes32) {
        require(catImagesUri.length >0 , "There are no blind box cats!");
        bytes32  requestId = oracle.getRandomNumber(userProvidedSeed);
        requestToCatName[requestId] = name;
        requestToSender[requestId] = msg.sender;
        emit ResultOfNewBlindboxCat(msg.sender,name,requestId);
        return requestId;
    }


    function generateBlindBoxCat(bytes32 requestId) public {
        require(catImagesUri.length >0 , "There are no blind box cats!");
        require(oracle.checkIdFulfilled(requestId) == false, " oracle query has not been fulfilled!");
        uint256 randomness  = oracle.getById(requestId);
        uint8 index = uint8((randomness) % catImagesUri.length);
        string name =  requestToCatName[requestId];
        // string  images = catImagesUri[index];
        string memory images = _podCatImage(index);
        uint256 birthTime = now;
        cats.push(Cat(name, index, birthTime, requestToSender[requestId], images));
        issueWithAssetURI(requestToSender[requestId], cats.length, images, "");
        emit SurpriseCat(requestId, name,index, birthTime,requestToSender[requestId], images);
    }


    function getCatInfo(uint256 catId)
    public
    view
    returns (string , uint8 , uint256 , address , string )
    {
        return (
        cats[catId].name,
        cats[catId].genes,
        cats[catId].birthTime,
        cats[catId].owner,
        cats[catId].images);
    }

    function _podCatImage(uint8 index)internal returns(string){
        string dataByIndex = catImagesUri[index];
        string lastElement = catImagesUri[catImagesUri.length-1];
        delete catImagesUri[catImagesUri.length - 1];
        catImagesUri.length = catImagesUri.length-1;
        return dataByIndex;
    }

    function getLength()public view returns(uint256){
        return catImagesUri.length;
    }
}
