angular.module("beamng.apps")
    .directive("tyreWearThermals", ["CanvasShortcuts", function(CanvasShortcuts) {
        return {
            template: '<canvas width="220"></canvas>',
            replace: true,
            restrict: "EA",
            link: function(scope, element, attrs) {
                var streamsList = ["tyrewearandthermals2"];
                StreamsManager.add(streamsList);
                scope.$on("$destroy", function() {
                    StreamsManager.remove(streamsList);
                });
                var c = element[0], ctx = c.getContext("2d");
                scope.$on('app:resized', function(event, data) {
                    c.width = data.width
                    c.height = data.height
                });
                let wheelCount;
                scope.$on("streamsUpdate", function(event, streams) {
                    // From: https://stackoverflow.com/a/3368118
                    var wheelCount = streams.tyrewearandthermals2.data.length;
                    function roundRect(
                        ctx,
                        x,
                        y,
                        width,
                        height,
                        radius = 5,
                        fill = false,
                        stroke = true
                    ) {
                        if (typeof radius === 'number') {
                            radius = { tl: radius, tr: radius, br: radius, bl: radius };
                        } else {
                            radius = { ...{ tl: 0, tr: 0, br: 0, bl: 0 }, ...radius };
                        }
                        ctx.beginPath();
                        ctx.moveTo(x + radius.tl, y);
                        ctx.lineTo(x + width - radius.tr, y);
                        ctx.quadraticCurveTo(x + width, y, x + width, y + radius.tr);
                        ctx.lineTo(x + width, y + height - radius.br);
                        ctx.quadraticCurveTo(x + width, y + height, x + width - radius.br, y + height);
                        ctx.lineTo(x + radius.bl, y + height);
                        ctx.quadraticCurveTo(x, y + height, x, y + height - radius.bl);
                        ctx.lineTo(x, y + radius.tl);
                        ctx.quadraticCurveTo(x, y, x + radius.tl, y);
                        ctx.closePath();
                        if (fill) {
                            ctx.fill();
                        }
                        if (stroke) {
                            ctx.stroke();
                        }
                    }

                    function drawWheelData(name, temps, working_temp, condition_zones, camber, tyreNumber) {
                        if (Object.keys(temps).length == 0) {
                            temps = Array(4).fill(0)
                        }

                        if (condition_zones == undefined) {
                            condition_zones = [100, 100, 100]
                        }

                        ctx.textAlign = 'center';

                        var right = 0;
                        var back = 0;

                        var w = c.width / 3.5;
                        var h = c.height / 3.5;
                        h = h / (wheelCount / 4)

                        if (wheelCount <= 4) {
                            if (name == "RR" || name == "RL") {
                                back = 1;
                            }

                            if (name == "FR" || name == "RR" || name == "RR2") {
                                right = 1;
                            }
                        } else {
                            if (tyreNumber % 2 == 1) {
                                right = 1
                            }
                            back = Math.floor(tyreNumber / 2)
                        }

                        var x = w * 0.5 + ((w * 1.5) * right);
                        var y = (h * 0.5 + ((h * 1.5) * back)) + h * 0.1;
                        var cx = x + w * 0.5;
                        var cy = y + h * 0.5;

                        h = h * 0.8;

                        // Draw info text
                        ctx.fillStyle = "#ffffffff";
                        ctx.font = 'bold 18pt "Lucida Console", Monaco, monospace';
                        var conditionAverage = condition_zones.reduce((a, b) => a + b, 0) / condition_zones.length;
                        ctx.fillText("" + Math.floor(conditionAverage) + "%", cx, y - 8);

                        var t = conditionAverage / 100;

                        var lowHue = 0;
                        var highHue = 248;

                        for (let i = 0; i < condition_zones.length; i++) {
                            var tempT = 1.0 - Math.min(Math.max(temps[i] / working_temp - 0.5, 0), 1);
                            var hue = lowHue + (highHue - lowHue) * tempT;

                            var crad = 8.0;
                            var radius = { tl: 0, tr: 0, br: 0, bl: 0 };
                            if (i == 0) {
                                radius = { tl: crad, tr: 0, br: 0, bl: crad };
                            } else if (i == condition_zones.length - 1) {
                                radius = { tl: 0, tr: crad, br: crad, bl: 0 };
                            }

                            const sectionWidth = (w / 3.0 - 1.5) / condition_zones.length * 3
                            const sectionXOffset = sectionWidth * i + 2
                            ctx.lineWidth = "0";
                            ctx.fillStyle = "rgba(0,0,0,0.45)";
                            ctx.beginPath();
                            ctx.rect(x + sectionXOffset, y + 1, sectionWidth, h - 2);
                            ctx.fill();
                            if (condition_zones[i] > 30) {
                                var ft = 1.0 - (condition_zones[i] / 100);
                                ctx.fillStyle = "hsla(" + hue + ",82%,56%,1)";
                                ctx.beginPath();
                                ctx.rect(x + sectionXOffset, y + h * ft + 1, sectionWidth, h - h * ft - 2);
                                ctx.fill();
                            }
                            ctx.lineWidth = "3";
                            ctx.strokeStyle = "rgba(0,0,0,1)";
                            roundRect(ctx, x + sectionXOffset, y, sectionWidth, h, radius, false);

                            // Info text
                            ctx.fillStyle = "#ffffffff";
                            var font_size = Math.max(Math.min(w / 20.0 * 3.0, 16.0), 4.0);
                            ctx.font = 'bold ' + font_size + 'pt "Lucida Console", Monaco, monospace';
                            if (i < 3) {
                                let middleTemp = 0
                                const middleIndex = Math.floor(temps.length / 2);

                                if (temps.length % 2 === 1) {
                                    // Odd length: return the middle value
                                    middleTemp = temps[middleIndex];
                                } else {
                                    // Even length: return the average of the two middle values
                                    const middleValue1 = temps[middleIndex - 1];
                                    const middleValue2 = temps[middleIndex];
                                    middleTemp = (middleValue1 + middleValue2) / 2;
                                }
                                const simpleTemps = [temps[0], middleTemp, temps[temps.length-1]]
                                ctx.fillText("" + Math.floor(simpleTemps[i]), x + (w / 3.0 * i) + 2 + (w / 3.0 - 8) / 2.0, y + h + 22);
                            }

                            // Load bias
                            // ctx.fillStyle = "rgba(255,50,50,0.85)";
                            // ctx.beginPath();
                            // ctx.moveTo(x + w * 0.5 + w * (load_bias * 0.5), y - 2);
                            // ctx.lineTo(x + w * 0.5 + w * (load_bias * 0.5) - 6, y - 8);
                            // ctx.lineTo(x + w * 0.5 + w * (load_bias * 0.5) + 6, y - 8);
                            // ctx.fill();
                            //
                            // ctx.beginPath();
                            // ctx.moveTo(x + w * 0.5 + w * (load_bias * 0.5), y + h + 2);
                            // ctx.lineTo(x + w * 0.5 + w * (load_bias * 0.5) - 6, y + h + 8);
                            // ctx.lineTo(x + w * 0.5 + w * (load_bias * 0.5) + 6, y + h + 8);
                            // ctx.fill();
                            // camber
                            ctx.fillStyle = "rgba(255,50,50,0.85)";
                            ctx.beginPath();
                            ctx.moveTo(x + w * 0.5 + w * (camber * 0.2 * 0.5), y - 2);
                            ctx.lineTo(x + w * 0.5 + w * (camber * 0.2 * 0.5) - 6, y - 8);
                            ctx.lineTo(x + w * 0.5 + w * (camber * 0.2 * 0.5) + 6, y - 8);
                            ctx.fill();

                            ctx.beginPath();
                            ctx.moveTo(x + w * 0.5 + w * (camber * 0.2 * 0.5), y + h + 2);
                            ctx.lineTo(x + w * 0.5 + w * (camber * 0.2 * 0.5) - 6, y + h + 8);
                            ctx.lineTo(x + w * 0.5 + w * (camber * 0.2 * 0.5) + 6, y + h + 8);
                            ctx.fill();
                        }
                        // Draw brakes
                        // var brakeTempT = 1.0 - Math.min(Math.max(brake_temp / brake_working_temp - 0.5, 0), 1);
                        // var brakeHue = lowHue + (highHue - lowHue) * brakeTempT;
                        // ctx.fillStyle = "hsla(" + hue + ",82%,56%,1)";
                        // roundRect(ctx, cx - w / 24.0 - w / 1.75 * (right * 2.0 - 1.0), y + h * 0.2, w / 12.0, h * 0.6, 3.0, true);
                        // Draw core temp
                        var coreTempT = 1.0 - Math.min(Math.max(temps[temps.length - 1] / working_temp - 0.5, 0), 1);
                        var coreHue = lowHue + (highHue - lowHue) * coreTempT;
                        let coreTempIsDisplayed;
                        if (t < 0.1) {
                            coreTempIsDisplayed = 0;
                            ctx.fillStyle = "rgba(0,0,0,0.45)";
                        } else {
                            ctx.fillStyle = "hsla(" + coreHue + ",82%,56%,1)";
                            coreTempIsDisplayed = 1;
                        }
                        if (right) {
                            roundRect(ctx, cx - w / 12.0 - w / 1.75, y + h * 0.2, w / 6, h * 0.6, 3.0, true);
                        } else {
                            roundRect(ctx, cx - w / 12.0 + w / 1.75, y + h * 0.2, w / 6, h * 0.6, 3.0, true);
                        }
                    }

                    var dataStream = streams.tyrewearandthermals2;
                    ctx.setTransform(1, 0, 0, 1, 0, 0); // No scaling, no skewing, no translation
                    ctx.clearRect(0, 0, c.width, c.height);

                    ctx.textAlign = 'center';

                    for (let i = 0; i < dataStream.data.length; i++) {
                        drawWheelData(
                            dataStream.data[i].name,
                            dataStream.data[i].temps,
                            dataStream.data[i].working_temp,
                            dataStream.data[i].condition_zones,
                            dataStream.data[i].camber,
                            i
                        );
                    }
                });
            }
        }
    }])
