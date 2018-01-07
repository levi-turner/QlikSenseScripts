-- Create the table
USE `machine_logs`;
CREATE TABLE `ini2counter_pi01` (
  `id` INT(20) NOT NULL,
  `cycle_date` DATE NOT NULL,
  `cycle_time` TIME(6),
  `datetime` TIME(6),
  `downtime` TIME(6),
  `start_time` TIME(6),
  `cycles` INT(10) NOT NULL,
  `runtime` TIME(6),
  PRIMARY KEY (`id`)
) ENGINE=INNODB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

-- Insert in data
-- Cleanup failed cycle_date value: DELETE FROM `machine_logs`.`ini2counter_pi01` WHERE  `id`=001
INSERT INTO `machine_logs`.`ini2counter_pi01` (
    `id`,
    `cycle_date`,
    `cycle_time`,
    `downtime`,
    `start_time`,
    `cycles`,
    `runtime`
    ) VALUES(
        001,
        '2017-10-27',
        '08:38:59.117878',
        '00:00:22.000000',
        '07:18:35.876830',
        45,
        '01:20:46.000000'
        );

-- Create the view;

Create View `machine_logs`.`ini2counter_pi01_view_last` AS
    SELECT 
        MAX(`machine_logs`.`ini2counter_pi01`.`cycle_date`) AS `cycle_date`,
        MAX(`machine_logs`.`ini2counter_pi01`.`cycle_time`) AS `cycle_time`,
        LEFT(TIMESTAMP(MAX(`machine_logs`.`ini2counter_pi01`.`cycle_date`),
                MAX(`machine_logs`.`ini2counter_pi01`.`cycle_time`)),
            19) AS `datetime`,
        MAX(`machine_logs`.`ini2counter_pi01`.`downtime`) AS `downtime`,
        MIN(`machine_logs`.`ini2counter_pi01`.`cycle_time`) AS `start_time`,
        COUNT(`machine_logs`.`ini2counter_pi01`.`cycle_time`) AS `cycles`,
		MAX(`machine_logs`.`ini2counter_pi01`.`runtime`) AS `runtime`
    FROM
        `machine_logs`.`ini2counter_pi01`