// SPDX-License-Identifier: MIT
interface IAsdicLpPool {
    struct StakedInfo {
        uint index;
        uint stakedAmount;
        uint updateTime;
        uint available;
        uint accruedReward;
    }
    function userStakedInfos(
        address user
    ) external view returns (StakedInfo memory);
}
